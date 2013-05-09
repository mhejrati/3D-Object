% Compute local mixture ids by clustering the deformation features
% [local_ids,local_visibility] = compute_local_ids(deformation_feat,
%                                visibility_feat,n_local_mixture)

function [local_ids,local_visibility] = compute_local_ids(deformation_feat,visibility_feat,n_local_mixture)

n_parts = length(deformation_feat);
tmp_local_ids = cell(1,n_parts);

% Compute local ids
for i = 1:n_parts
    for j = 1:n_parts
        tdef1(i,j,:) = deformation_feat{i}(:,1) - deformation_feat{j}(:,1);
        tdef2(i,j,:) = deformation_feat{i}(:,2) - deformation_feat{j}(:,2);
    end
end

for p = 1:n_parts
  X = squeeze([tdef1(p,:,:) tdef2(p,:,:)])';
  idx{p} = zeros(1,size(X,1));
  local_visibility{p} = [];
  visibility_types = unique(visibility_feat{p});
  n_visibility_types = length(visibility_types);
  for i = 1:n_visibility_types
    tmp_ids = find(visibility_feat{p}==visibility_types(i));
    tmp_clusters = kmeans(X(tmp_ids,:),n_local_mixture,'emptyaction','single','replicate',50);
    idx{p}(tmp_ids) = tmp_clusters + (i-1)*n_local_mixture;
    local_visibility{p}(end+1:end+n_local_mixture) = visibility_types(i)*ones(1,n_local_mixture);
  end
  local_ids{p} = idx{p};
end
