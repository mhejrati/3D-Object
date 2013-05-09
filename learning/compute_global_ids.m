% Compute global mixture ids and tree structure using EM algorithm
% [tree_structs,global_ids, n_global_mixture] = compute_global_ids(pos,n_global_mixture);

function [tree_structs,global_ids, n_global_mixture] = compute_global_ids(pos,n_global_mixture)
  n_parts = size(pos(1).point,1);
  max_iter = 50;
  % Compute normalized point locations
  for j = 1:length(pos)
    pos_id = j;
    for p = 1:n_parts
      points{p}(j,1) = (pos(pos_id).point(p,1)-pos(pos_id).pascal_box(1))/pos(pos_id).part_size;
      points{p}(j,2) = (pos(pos_id).point(p,2)-pos(pos_id).pascal_box(2))/pos(pos_id).part_size;
    end
  end
  
  % Compute initial global IDs
  for i = 1:n_parts
    tdef1(i,:) = points{i}(:,1) - points{1}(:,1);
    tdef2(i,:) = points{i}(:,2) - points{1}(:,2);
  end
  X = squeeze([tdef1 ; tdef2])';
  global_ids = kmeans(X,n_global_mixture,'emptyaction','drop','replicate',50);
  
  for i = 1:n_global_mixture
    if sum(global_ids==i)<2
      global_ids(global_ids==i)=0;
    end
  end
  %visualize_cluster(global_ids,pos,n_global_mixture)
  
  % EM
  for i = 1:max_iter
    % M-step : Compute tree structure and parameters
    [Trees,Sigma,Mu] = update_tree(points,global_ids);
    % E-step : Update global mixture assignments
    all_gloabl_ids{i} = global_ids;
    [new_global_ids,scores] = update_global_ids(points,Trees,Sigma,Mu);
    sum_scores(i) = sum(scores);
    fprintf('Iteration %1d , score = %.1f \n',i,sum_scores(i));
    if global_ids == new_global_ids
      break;
    end
    if i>1
      if abs(sum_scores(i)-sum_scores(i-1))<1e-5
        break;
      end
    end
    global_ids = new_global_ids;
  end
  
  % Wrap output
  tree_structs.colorset = hsv(n_parts);
  tree_structs.part_names = pos(1).part_names;
  cnt = 0;
  for i = 1:max(global_ids)
    if sum(global_ids==i)>0
      cnt = cnt+1;
      global_ids(global_ids==i) = cnt;
      tree_structs.pa{cnt} = Trees(i).tree.pa;
    end
  end
  n_global_mixture = cnt;
  
%   % Debugging visualizations
%   figure;plot(1:length(sum_scores),sum_scores)
%   visualize_cluster_evloution(all_gloabl_ids,pos,n_global_mixture)
%   visualize_cluster(global_ids,pos,n_global_mixture)
  

% Compute Tree structs
function [Trees,Sigma,Mu] = update_tree(points,global_ids)
  n_global = max(global_ids);
  nparts = length(points);
  for g = 1:n_global
    tmp_ids = global_ids==g;
    for i = 1:nparts
      for j = 1:nparts
        if i==j
          weights(i,j) = 0;
        else
          part1 = points{i}(tmp_ids,:);
          part1 = part1 - repmat(mean(part1),[size(part1,1) 1]);

          part2 = points{j}(tmp_ids,:);
          part2 = part2 - repmat(mean(part2),[size(part2,1) 1]);
          
          w = log(det(cov(part1)) * det(cov(part2)) / det(cov(part1,part2)))/2;
          weights(i,j) = w;
          
          Mu{g,i,j} = mean(points{j}(tmp_ids,:) - points{i}(tmp_ids,:));
          assert(isequal(size(Mu{g,i,j}),[1 2]))
          
          Sigma{g,i,j} = sqrt(mean( ((points{j}(tmp_ids,:) - points{i}(tmp_ids,:)) - repmat(Mu{g,i,j},[size(part1,1) 1])).^2));
        end
      end
    end
    % compute the maximum spanning tree
    [tree_matrix,cost] = MaximumSpanningTree(weights);
    tree = compile_tree(tree_matrix);
    %visualize_tree(points,tree_matrix,tmp_ids);
    Trees(g).tree = tree;
    Trees(g).cost = cost;
  end
  
  
function [new_global_ids,scores] = update_global_ids(points,Trees,Sigma,Mu)
  n_global = length(Trees);
  n_parts = length(points);
  n_pos = size(points{1},1);
  for i = 1:n_pos
    for p = 1:n_parts
      x(p,:) = points{p}(i,:);
    end
    for g = 1:n_global
      score(i,g) = compute_score(x,Trees(g),Sigma(g,:,:),Mu(g,:,:));
    end
  end
  [scores,new_global_ids] = max(score,[],2);
  for i = 1:n_global
    if sum(new_global_ids==i)<2
      new_global_ids(new_global_ids==i)=0;
    end
  end
  
function score = compute_score(points,tree,Sigma,Mu)
  score = 0;
  pa = tree.tree.pa;
  for i = 2:length(pa)
    x1 = points(i,1);
    y1 = points(i,2);
    x2 = points(pa(i),1);
    y2 = points(pa(i),2);
    mu = Mu{1,pa(i),i};
    sigma = Sigma{1,pa(i),i};
    px = exp(-0.5*(((x1-x2)-mu(1))/sigma(1))^2) / (sqrt(2*pi)*sigma(1));
    py = exp(-0.5*(((y1-y2)-mu(2))/sigma(2))^2) / (sqrt(2*pi)*sigma(2));
    score = score + log(px*py);
  end
  
function tree_struct = compile_tree(tree_matrix)
  nparts = size(tree_matrix,1);
  cnt = 1;
  pa(1) = 0;
  stack = 1;
  free_nodes = ones(1,nparts);
  free_nodes(1) = 0;

  while length(stack)>0
    for i = 1:nparts
      if tree_matrix(stack(1),i) && free_nodes(i)
        stack(end+1) = i;
        cnt = cnt+1;
        pa(i) = stack(1);
        free_nodes(i) = 0;
      end
    end
    stack = stack(2:end);
  end

  % The parent vector after transformation is applied
  tree_struct.pa = pa;
  
  
function visualize_cluster(global_ids,pos,n_global)
  close all
  for j = 1:n_global
    figure;
    ids = find(global_ids==j);
    for i = 1:min(length(ids),25)
      subplot(5,5,i)
      id = ids(i);
      im = imread(pos(id).im);
      x1 = max(pos(id).box(1),1);
      y1 = max(pos(id).box(2),1);
      x2 = min(pos(id).box(3),size(im,2));
      y2 = min(pos(id).box(4),size(im,1));
      im = im(y1:y2,x1:x2,:);
      imshow(im)
    end    
  end
  
  
function visualize_cluster_evloution(global_ids,pos,n_global)
%  close all
  for j = 1:n_global
    figure;
    for t = 1:length(global_ids)
      ids = find(global_ids{t}==j);
      for i = 1:min(length(ids),20)
        k = 20*(t-1)+i;
        subplot(length(global_ids),20,k)
        id = ids(i);
        im = imread(pos(id).im);
        x1 = max(pos(id).box(1),1);
        y1 = max(pos(id).box(2),1);
        x2 = min(pos(id).box(3),size(im,2));
        y2 = min(pos(id).box(4),size(im,1));
        im = im(y1:y2,x1:x2,:);
        imshow(im)
      end    
    end
  end
  
function visualize_tree(points,tree,ids)
nparts = length(points);
colorset = hsv(nparts);
figure;
for i = 1:nparts
    hold on
    scatter(points{i}(ids,1),points{i}(ids,2),10,colorset(i,:));
    scatter(mean(points{i}(ids,1)),mean(points{i}(ids,2)),50,colorset(i,:),'filled');
end

for i = 1:nparts
    for j = 1:nparts
        if tree(i,j)
            line([mean(points{i}(ids,1)),mean(points{j}(ids,1))],[mean(points{i}(ids,2)),mean(points{j}(ids,2))],'linewidth',2);
        end
    end
end