function visualize_boxes(im, boxes, colors, names, h)
  n_boxes = size(boxes,1);
  
  if nargin<5
    h = figure;
  end
  if isempty(h)
    h = figure;
  end

  if nargin<4
    names = cell(n_boxes,1);
  end
  if isempty(names)
    names = cell(n_boxes,1);
  end

  if nargin<3
    colors = hsv(n_boxes);
  end
  if isempty(colors)
    colors = hsv(n_boxes);
  end

  if isempty(im)
    im = imread(detections.im);
  end
  
  clf(h);

  imagesc(im); axis image; axis off;
  hold on
  
  if ~isempty(boxes)
    for i = 1:n_boxes
      x1 = boxes(i,1);
      y1 = boxes(i,2);
      x2 = boxes(i,3);
      y2 = boxes(i,4);

      line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', colors(i,:), 'linewidth', 2);
      if ~isempty(names{i})
        text(x1,y1,names{i},'BackgroundColor',colors(i,:),'FontSize',8)
      end
    end
  end
