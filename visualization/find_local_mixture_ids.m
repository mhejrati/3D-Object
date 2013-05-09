% Find the configuration with the largest sum of biasses (most likely configuration)
% local_mixture_ids = find_local_mixture_ids(model,c)

function local_mixture_ids = find_local_mixture_ids(model,c)
  n_parts = length(c);
  
  % precompute bias values and store it into model.component structure,
  % just to make future computation cleaner
  for i = 1:n_parts
    c(i).bias_vals = zeros(size(c(i).biasid));
    [m,n] = size(c(i).biasid);
    for mi = 1:m
      for ni = 1:n
        c(i).bias_vals(mi,ni) = model.bias(c(i).biasid(mi,ni)).w;
      end
    end
  end
  
  % Recursively walk from leaves to root and find and compute the best sum
  % of biasses from leaves to any node
  c = find_local_mixture_ids_recursive(model,c,1);
  
  % Walk back from root to leaves and get the local mixture ids
  local_mixture_ids = backtrack(model,c);

function local_mixture_ids = backtrack(model,c)
  n_parts = length(c);
  local_mixture_ids = zeros(1,n_parts);
  
  [dum,tmp_id] = max(c(1).best_conf_score);
  local_mixture_ids(1) = tmp_id;
  
  for i = 1:n_parts
    % get list of children
    cnt = 0;
    for j = 1:n_parts
      if c(j).parent == i
        cnt = cnt+1;
        local_mixture_ids(j) = c(i).best_conf_ids(local_mixture_ids(i),cnt);
      end
    end
  end
  

function c = find_local_mixture_ids_recursive(model,c,root)
  
  n_parts = length(c);
  root_n_local_mixture = length(c(root).filterid);
  children_list = [];
  
  % find all children of the root
  for i = 1:n_parts
    if c(i).parent == root
      children_list = [children_list i];
    end
  end
  
  n_children = length(children_list);
  c(root).best_conf_score = zeros(root_n_local_mixture,1);
  c(root).best_conf_ids = zeros(root_n_local_mixture,n_children);
  
  % compute the best configuration for each of children
  for i = 1:length(children_list)
    c = find_local_mixture_ids_recursive(model,c,children_list(i));
  end
  
  % combine results
  for i = 1:root_n_local_mixture
    for j = 1:n_children
      tc = c(children_list(j));
      tscores = tc.best_conf_score + tc.bias_vals(i,:)';
      [best_score,best_score_id] = max(tscores);
      c(root).best_conf_score(i) = c(root).best_conf_score(i)+best_score;
      c(root).best_conf_ids(i,j) = best_score_id; 
    end
  end
  