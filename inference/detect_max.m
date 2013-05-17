function detections = detect_max(im, model, annotation, overlap)
  
  % First run detection for the image using a low threshold
  model.interval = 10;
  detections = detect_fast(im, model, -1.5, true);
  
  % Keep detections with sufficient overlap
  detections = bestoverlap(detections, annotation, overlap);  
  

function detections = bestoverlap(detections, annotation, overlap)

  if isempty(detections) || isempty(annotation)
    return;
  end

  if nargin < 3
    overlap = 0.5;
  end

  for i = 1:length(detections)
    bx1(i) = min(detections(i).part_boxes(:,1));
    by1(i) = min(detections(i).part_boxes(:,2));
    bx2(i) = max(detections(i).part_boxes(:,3));
    by2(i) = max(detections(i).part_boxes(:,4));
  end
  
  x1 = annotation.box(1);
  y1 = annotation.box(2);
  x2 = annotation.box(3);
  y2 = annotation.box(4);
  area = (x2-x1+1).*(y2-y1+1);
  barea = (bx2 - bx1 + 1) .* (by2 - by1 + 1);

  xx1 = max(x1,bx1);
  yy1 = max(y1,by1);
  xx2 = min(x2,bx2);
  yy2 = min(y2,by2);

  w = xx2-xx1+1; w(w<0) = 0;
  h = yy2-yy1+1; h(h<0) = 0;
  inter = w.*h;
  o = inter ./ (barea + area - inter);

  I = o > overlap;
  detections = detections(I);