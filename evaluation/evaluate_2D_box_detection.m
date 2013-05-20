function result = evaluate_2D_box_detection(test,experiment_name, experiment_name_suffix,params)

  % Load detections, run NMS and prepare input for evaluation
  globals;
  overlap = 0.5;
  dir_name = fullfile(cachedir,'detections', [experiment_name '_' experiment_name_suffix]);
  cnt = 0;
  do_clip = true;
  
  % Avoid duplicate images, because evaluation penalizes for duplicate
  % detections
  for i = 1:length(test)
    tnames{i} = test(i).im;
  end
  [names,a,b] = unique(tnames);
  
  
  for i = 1:length(a)
    fprintf('Reading detections for %d image.\n',i)
    ttest = test(a(i));
    im = imread(ttest.im);
    [ymx,xmx,c] = size(im);
    load(fullfile(dir_name, [num2str(a(i)) '_boxes.mat']))
    detection = nms(detection,overlap,do_clip,xmx,ymx);
    for j = 1:length(detection)
      cnt = cnt+1;
      if cnt == 1
        detections = detection(j);
        detections.im = ttest.im;
        detections(100000) = detections(1);
      else
        tdetection = detection(j);
        tdetection.im = ttest.im;
        detections(cnt) = tdetection;
      end
    end
  end
  detections = detections(1:cnt);

  % evaluate detections
  params.min_overlap = overlap;
  result = eval_detection(test(a),detections,params);
