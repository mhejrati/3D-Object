% needs documentation

function model = train_model(pos, neg, hog_sbin, n_local_mixture, ...
                 n_global_mixture, experiment_name, experiment_name_suffix)
  globals;
  diary_filename = fullfile(cachedir,[experiment_name '_train_diary_' experiment_name_suffix '_' datestr(now) '.log']);
  diary(diary_filename)
  n_parts = size(pos(1).point,1);

  % Compute Global and Local Clusters
  cls = [experiment_name '_clusters_' experiment_name_suffix];
  try
    load(fullfile(cachedir, cls));
  catch
    model = initmodel(pos,hog_sbin);
    
    % Compute deformation and visibility features
    [deformation_feat,visibility_feat] = data_def(pos,model);
    
    % Compute local mixture ids for each part %%% NEEDS better documentation 
    [local_ids,local_visibility] = compute_local_ids(deformation_feat,visibility_feat,n_local_mixture);
    
    % Visualize local clustering, good for debugging
    % visualize_local_clusters(pos,local_ids,1)
    
    % Compute global mixture ids and tree structure using EM algorithm
    [tree_structs,global_ids, n_global_mixture] = compute_global_ids(pos,n_global_mixture);
    
    save([cachedir cls],'deformation_feat','visibility_feat','local_ids',...
          'local_visibility','global_ids','tree_structs','n_global_mixture');
  end

% Initialize local templates  
for p = 1:n_parts
  cls = [experiment_name '_part_' num2str(p) '_' experiment_name_suffix];
  try
    load([cachedir cls]);
  catch
    sneg = neg(1:min(length(neg),100));
    model = initmodel(pos,hog_sbin);
    models = cell(1,length(local_visibility{p}));
    parfor k = 1:length(local_visibility{p})
      spos = pos(local_ids{p} == k);
      tspos = struct('bbox',{},'skip',{},'im',{});
      for n = 1:length(spos)
        tspos(n).bbox = [spos(n).x1(p) spos(n).y1(p) spos(n).x2(p) spos(n).y2(p)];
        tspos(n).skip = false;
        tspos(n).im = spos(n).im;
      end
      models{k} = train(cls,model,tspos,sneg,1,1);
    end
    model = mergemodels(models);
    save([cachedir cls],'model');
  end
end
  
cls = [experiment_name '_final_' experiment_name_suffix];
try
  load([cachedir cls]);
catch
  [jointmodel,new_pos] = buildmodel(model, pos, deformation_feat, ...
         local_ids, global_ids, tree_structs, local_visibility, ...
         experiment_name,experiment_name_suffix);
  %  visualizemodel2(jointmodel,global_ids(i),valid_combs(i,:));
  model = train(cls,jointmodel,new_pos,neg,0,1);
  save([cachedir cls],'model');
end
