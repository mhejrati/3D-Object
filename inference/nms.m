function [top,pick] = nms(boxes,overlap,numpart)
% Non-maximum suppression.
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected detection.

if nargin < 2
    overlap = 0.5;
end
if nargin < 3
    numpart = floor(size(boxes,2)/4);
end

if isempty(boxes)
  top = [];
else
  % Prune to top 1000 candidates for speed
  if size(boxes,1) > 1000,
    [foo,I] = sort(boxes(:,end),'descend');
    boxes = boxes(I(1:1000),:);
  end
  x1 = zeros(size(boxes,1),numpart);
  y1 = zeros(size(boxes,1),numpart);
  x2 = zeros(size(boxes,1),numpart);
  y2 = zeros(size(boxes,1),numpart);
  area = zeros(size(boxes,1),numpart);
  for p = 1:numpart
    x1(:,p) = boxes(:,1+(p-1)*4);
    y1(:,p) = boxes(:,2+(p-1)*4);
    x2(:,p) = boxes(:,3+(p-1)*4);
    y2(:,p) = boxes(:,4+(p-1)*4);
    area(:,p) = (x2(:,p)-x1(:,p)+1) .* (y2(:,p)-y1(:,p)+1);
  end
  
  s = boxes(:,end);
  [vals, I] = sort(s);
  pick = [];
  while ~isempty(I)
    last = length(I);
    i = I(last);
    pick = [pick; i];

    xx1 = bsxfun(@max,x1(i,:), x1(I,:));
    yy1 = bsxfun(@max,y1(i,:), y1(I,:));
    xx2 = bsxfun(@min,x2(i,:), x2(I,:));
    yy2 = bsxfun(@min,y2(i,:), y2(I,:));
    
    w = xx2-xx1+1;
    w(w<0) = 0;
    h = yy2-yy1+1;
    h(h<0) = 0;    
    inter  = sum(w.*h,2);
    o = inter ./ sum(area(I,:),2);
    I(o > overlap) = [];
  end  
  top = boxes(pick,:);
end
