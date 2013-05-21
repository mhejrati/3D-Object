function result = evaluate_Landmarks(test, model, experiment_name, experiment_name_suffix, params)

  if nargin<5
    params = [];
  end
  
  % Load detections, run NMS and prepare input for evaluation
  globals;
  dir_name = fullfile(cachedir,'detections_given_bbox', [experiment_name '_' experiment_name_suffix]);
  cnt = 0;
  
  for i = 1:length(test)
    fprintf('Reading detections for %d image.\n',i)
    im = imread(test(i).im);
    [ymx,xmx,c] = size(im);
    load(fullfile(dir_name, [num2str(i) '_boxes.mat']))
    if isempty(detection)
      continue;
    end
    sc = [];
    for j = 1:length(detection)
      sc(j) = detection(j).score;
    end
    [dummy m_id] = max(sc);
  
    cnt = cnt+1;
    if cnt == 1
      detections = detection(m_id);
      detections.im = test(i).im;
      all_test = test(i);
    else
      tdetection = detection(m_id);
      tdetection.im = test(i).im;
      detections(cnt) = tdetection;
      all_test(cnt) = test(i);
    end
  end

  % evaluate detections
  result = eval_landmark_localization(all_test,detections,model,params);