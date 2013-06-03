function visualize_detected_boxes(im, detections, params)

  if nargin<3
    h = figure;
    params.figure = h;
  end

  if isempty(im)
    im = imread(detections.im);
  end
  
  boxes = [];
  names = {};
  if ~isempty(detections)
    for d = 1:length(detections)
      detection = detections(d);
      x1 = detection.box(1);
      y1 = detection.box(2);
      x2 = detection.box(3);
      y2 = detection.box(4);

      boxes(d,:) = [x1 y1 x2 y2];
      try
        names{d} = num2str(detection.score);
      catch
        names{d} = '';
      end
    end
  end

  visualize_boxes(im, boxes, [], names, params.figure)