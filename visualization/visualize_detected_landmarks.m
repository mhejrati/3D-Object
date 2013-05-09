% Show detected boxes for a detection
% visualize_detected_landmarks(im, model, detections,h)

function visualize_detected_landmarks(im, model, detections,h)

if nargin<4
  h = figure;
end

points = [];
colors = [];
names = {};
if ~isempty(detections)
    for d = 1:length(detections)
        detection = detections(d);
        for p = 1:length(detection.filterid)
            x1 = detection.part_boxes(p,1);
            y1 = detection.part_boxes(p,2);
            x2 = detection.part_boxes(p,3);
            y2 = detection.part_boxes(p,4);

            xm = mean([x1,x2]);
            ym = mean([y1,y2]);

            points = [points; xm ym];
            colors = [colors; model.filters(detection.filterid(p)).color];
            names{end+1} = model.filters(detection.filterid(p)).name;
        end
    end
    show_2D_point_cloud(im, points, colors,names,[],h)
end


