function [top] = nms(detections,overlap,xmx,ymx)
% Non-maximum suppression.
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected detection.

if nargin < 2
    overlap = 0.5;
end

sc = zeros(1,length(detections));
for d = 1:length(detections)
  sc(d) = detections(d).score;
end

if isempty(detections)
  top = [];
else
  % Prune to top 5000 candidates for speed
  if length(sc) > 5000,
    [foo,I] = sort(sc,'descend');
    detections = detections(I(1:5000));
    sc = sc(I(1:5000));
  end
  x1 = zeros(length(detections),1);
  y1 = zeros(length(detections),1);
  x2 = zeros(length(detections),1);
  y2 = zeros(length(detections),1);
  area = zeros(length(detections),1);
  for d = 1:length(detections)
%     x1(d) = max(1,min(detections(d).part_boxes(:,1)));
%     y1(d) = max(1,min(detections(d).part_boxes(:,2)));
%     x2(d) = min(xmx,max(detections(d).part_boxes(:,3)));
%     y2(d) = min(ymx,max(detections(d).part_boxes(:,4)));
    x1(d) = min(detections(d).part_boxes(:,1));
    y1(d) = min(detections(d).part_boxes(:,2));
    x2(d) = max(detections(d).part_boxes(:,3));
    y2(d) = max(detections(d).part_boxes(:,4));
    detections(d).box = [x1(d) y1(d) x2(d) y2(d)];
    area(d) = (x2(d)-x1(d)+1) .* (y2(d)-y1(d)+1);
    if area(d)<0
      fprintf('BAD NMS');
      top = [];
      return
    end
  end
  
  [vals, I] = sort(sc);
  pick = [];
  while ~isempty(I)
    last = length(I);
    i = I(last);
    pick = [pick; i];

    xx1 = bsxfun(@max,x1(i), x1(I));
    yy1 = bsxfun(@max,y1(i), y1(I));
    xx2 = bsxfun(@min,x2(i), x2(I));
    yy2 = bsxfun(@min,y2(i), y2(I));
    
    w = xx2-xx1+1;
    w(w<0) = 0;
    h = yy2-yy1+1;
    h(h<0) = 0;    
    inter  = sum(w.*h,2);
    o = inter ./ sum(area(I,:),2);
    I(o > overlap) = [];
  end  
  top = detections(pick);
end