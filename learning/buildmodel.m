function [jointmodel,new_pos] = buildmodel(model, pos, deformation_feat, ...
         local_mixture_ids, global_mixture_ids, tree_structs, local_visibility, ...
         experiment_name,experiment_name_suffix)

  globals;
  n_global = length(tree_structs.pa);
  n_parts = length(tree_structs.part_names);
  INF = 100;
  
  jointmodel.bias    = struct('w',{},'i',{});
  jointmodel.defs    = struct('w',{},'i',{},'anchor',{});
  jointmodel.filters = struct('w',{},'i',{},'name',{},'color',{},'visibility',{});
  for i = 1:n_global
      jointmodel.components{i} = struct('biasid',{},'defid',{},'filterid',{},'parent',{});
  end

  jointmodel.maxsize  = model.maxsize;
  jointmodel.interval = model.interval;
  jointmodel.sbin = model.sbin;
  jointmodel.len = 0;

  % Add all filters
  for i = 1:n_parts
    cls = [experiment_name '_part_' num2str(i) '_' experiment_name_suffix];
    load([cachedir cls]);

    % add filter
    for k = 1:length(model.filters)
      nf  = length(jointmodel.filters);
      f.w = model.filters(k).w;
      f.i = jointmodel.len + 1;
      f.name = tree_structs.part_names{i};
      f.color = tree_structs.colorset(i,:);
      f.visibility = local_visibility{i}(k);
      jointmodel.filters(nf+1) = f;
      jointmodel.len = jointmodel.len + numel(f.w);
      filter_ids(i,k) = nf+1;
    end
  end

  % add a constant big negative bias
  nb = length(jointmodel.bias);
  b.w = -INF;
  b.i = jointmodel.len + 1;
  jointmodel.bias(nb+1) = b;
  jointmodel.len = jointmodel.len + numel(b.w);
  inf_bias_id = nb+1;

  % add dumb deformation
  nd  = length(jointmodel.defs);
  d.w = [0.001 0 0.001 0];
  d.i = jointmodel.len + 1;
  d.anchor = round([1 1 0]);
  jointmodel.defs(nd+1) = d;
  jointmodel.len = jointmodel.len + numel(d.w);	
  dum_def_id = nd+1;

  % for each global mixture, compute the valid local mixture combinations
  mix = cell2mat(local_mixture_ids')';
  for i = 1:max(global_mixture_ids)
    t_local_mixtures = mix(find(global_mixture_ids==i),:);
    for p = 1:n_parts
      global_mixture_valid_combs{i,p}=unique(t_local_mixtures(:,p));
    end
  end

  % add global mixtures
  cnt_global = 0;
  for i = 1:n_global
    
    % ignore global mixture if one part has no local mixture
    skipflag = false;
    for p = 1:n_parts
      if isempty(global_mixture_valid_combs{i,p})
        skipflag = true;
      end
    end
    if skipflag
      continue;
    else
      cnt_global = cnt_global+1;
    end
    
    % compute the parent vector and the order of parts for each tree
    % structure
    %[n_child,n_pa,pa] = dfs(tree_structs.pa{i}); %%% Should be removed
    [orig_child_vector,orig_pa_vector,new_pa_vector] = dfs(tree_structs.pa{i});
    % add children
    for p = 1:n_parts
      orig_child = orig_child_vector(p);
      orig_parent = orig_pa_vector(p);
      child = p;
      parent = new_pa_vector(p);

      part.biasid = [];
      part.defid = [];
      if parent == 0
        % add bias for root
        nb = length(jointmodel.bias);
        b.w = 0;
        b.i = jointmodel.len+1;
        jointmodel.bias(nb+1) = b;
        jointmodel.len = jointmodel.len + numel(b.w);
        part.biasid = nb+1;
      else
        for kc = 1:length(global_mixture_valid_combs{i,orig_child})
          % add deformation
          k = global_mixture_valid_combs{i,orig_child}(kc);
          for lc = 1:length(global_mixture_valid_combs{i,orig_parent})
            l = global_mixture_valid_combs{i,orig_parent}(lc);
            % find instances that local mixtures co-occur
            tmp_ids = (mix(:,orig_child)==k) & (mix(:,orig_parent)==l);
            if sum(tmp_ids)==0
              part.biasid(lc,kc) = inf_bias_id;
              part.defid(lc,kc) = dum_def_id;
              % add a constant big negative bias
              nb = length(jointmodel.bias);
              b.w = -INF;
              b.i = jointmodel.len + 1;
              jointmodel.bias(nb+1) = b;
              jointmodel.len = jointmodel.len + numel(b.w);
              part.biasid(lc,kc) = nb+1;
              
              % add dumb deformation
              nd  = length(jointmodel.defs);
              d.w = [0.001 0 0.001 0];
              d.i = jointmodel.len + 1;
              d.anchor = round([1 1 0]);
              jointmodel.defs(nd+1) = d;
              jointmodel.len = jointmodel.len + numel(d.w);	
              part.defid(lc,kc) = nd+1;
            else
              % add bias
              nb = length(jointmodel.bias);
              b.w = 0;
              b.i = jointmodel.len + 1;
              jointmodel.bias(nb+1) = b;
              jointmodel.len = jointmodel.len + numel(b.w);
              part.biasid(lc,kc) = nb+1;

              % add deformation
              nd  = length(jointmodel.defs);
              d.w = [0.01 0 0.01 0];
              %d.w = [0.001 0 0.001 0];
              d.i = jointmodel.len + 1;
              x = mean(deformation_feat{orig_child}(tmp_ids,1) - deformation_feat{orig_parent}(tmp_ids,1)); 
              y = mean(deformation_feat{orig_child}(tmp_ids,2) - deformation_feat{orig_parent}(tmp_ids,2));
              d.anchor = round([x+1 y+1 0]);
              jointmodel.defs(nd+1) = d;
              jointmodel.len = jointmodel.len + numel(d.w);	
              part.defid(lc,kc) = nd+1;
            end
          end
        end
      end
      
      % add filters
      part.filterid = [];
      for kc = 1:length(global_mixture_valid_combs{i,orig_child})
        k = global_mixture_valid_combs{i,orig_child}(kc);
        nf = filter_ids(orig_child,k);
        part.filterid = [part.filterid nf];
      end
      part.parent = parent;
      np = length(jointmodel.components{i});
      jointmodel.components{i}(np+1) = part;
    end

  end   % loop over global mixtures

%   for i = 1:length(pos)
%       gi = global_mixture_ids(i);
%       [n_child,n_pa,pa] = dfs(tree_structs.pa{gi});
%       for p = 1:n_parts
%           valid_combs(i,p) = find(global_mixture_valid_combs{gi,n_child(p)} == mix(i,n_child(p)));
%           assert(valid_combs(i,p)<=length(jointmodel.components{gi}(p).filterid))
%       end
%   end

  % prepare positives
  bbox_zero = struct('bbox',[],'skip',true);
  for i = 1:length(jointmodel.filters)
    bbox_zero(i).bbox = [0 0 0 0];
    bbox_zero(i).skip = true;
  end

  new_pos = pos;
  for i = 1:length(pos)
    %new_pos(i) = pos(i);
%     fin_pos(i).im = pos(i).im;
    tbbox = bbox_zero;
    for p = 1:length(pos(i).x1)
      filter_id = filter_ids(p,mix(i,p));
      tbbox(filter_id).bbox = [pos(i).x1(p) pos(i).y1(p) pos(i).x2(p) pos(i).y2(p)];
      tbbox(filter_id).skip = false;
    end
    new_pos(i).part_boxes = tbbox;
%     fin_pos(i).box = pos(i).box;   %%% Should be investigated
%     fin_pos(i).point = pos(i).point;
%     fin_pos(i).part_size = pos(i).part_size;
  end