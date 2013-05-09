function [deformation_feat,visibility_feat] = data_def(pos,model)
n_parts = size(pos(1).point,1);
width  = zeros(1,length(pos));
height = zeros(1,length(pos));
labels = zeros(size(pos(1).point,1),size(pos(1).point,2),length(pos));
for n = 1:length(pos)
  width(n)  = pos(n).x2(1) - pos(n).x1(1);
  height(n) = pos(n).y2(1) - pos(n).y1(1);
  labels(:,:,n) = pos(n).point;
  if isfield(pos,'visibility')
    visibility_labels(:,n) = pos(n).visibility;
  else
    visibility_labels(:,n) = ones(n_parts,1);
  end
end
scale = sqrt(width.*height)/sqrt(model.maxsize(1)*model.maxsize(2));
scale = [scale; scale];

deformation_feat = cell(1,size(labels,1));
visibility_feat = cell(1,size(labels,1));
def0 = squeeze(labels(1,1:2,:));
for p = 1:size(labels,1)
  def = squeeze(labels(p,1:2,:));
  def = (def - def0) ./ scale;
  deformation_feat{p} = def';
  visibility_feat{p} = visibility_labels(p,:);
end