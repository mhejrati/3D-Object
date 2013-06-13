function [top] = nms(detections,overlap,params,xmx,ymx)
% Non-maximum suppression.
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected detection.

if nargin < 2
  overlap = 0.5;
end

if nargin<3
  params.do_clip = true;
  params.point_name = 'point';
  params.score_name = 'score';
end

if ~isfield(params,'do_clip')
  params.do_clip = true;
end

if ~isfield(params,'point_name')
  params.point_name = 'point';
end

if ~isfield(params,'score_name')
  params.score_name = 'score';
end

sc = zeros(1,length(detections));
for d = 1:length(detections)
  sc(d) = detections(d).(params.score_name);
  %detections(d).score = detections(d).(params.score_name);
  %sc(d) = detections(d).score;
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
    tmp_points = detections(d).(params.point_name);
    tmp_part_size = (detections(d).part_boxes(1,3)-detections(d).part_boxes(1,1))/2;
    if params.do_clip
      % Clip boxes
%       tx1(d) = max(1,min(detections(d).part_boxes(:,1)));
%       ty1(d) = max(1,min(detections(d).part_boxes(:,2)));
%       tx2(d) = min(xmx,max(detections(d).part_boxes(:,3)));
%       ty2(d) = min(ymx,max(detections(d).part_boxes(:,4)));
      x1(d) = max(1,min(tmp_points(:,1))-tmp_part_size);
      y1(d) = max(1,min(tmp_points(:,2))-tmp_part_size);
      x2(d) = min(xmx,max(tmp_points(:,1))+tmp_part_size);
      y2(d) = min(ymx,max(tmp_points(:,2))+tmp_part_size);
    else
%       x1(d) = min(detections(d).part_boxes(:,1));
%       y1(d) = min(detections(d).part_boxes(:,2));
%       x2(d) = max(detections(d).part_boxes(:,3));
%       y2(d) = max(detections(d).part_boxes(:,4));
      x1(d) = min(tmp_points(:,1)-tmp_part_size);
      y1(d) = min(tmp_points(:,2)-tmp_part_size);
      x2(d) = max(tmp_points(:,1)+tmp_part_size);
      y2(d) = max(tmp_points(:,2)+tmp_part_size);
    end
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