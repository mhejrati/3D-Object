function result = evaluate_2D_box_detection(test,experiment_name, experiment_name_suffix,params)

  if nargin<4
    params.point_name = 'point';
    params.score_name = 'score';
  end
  
  if ~isfield(params,'point_name')
    params.point_name = 'point';
  end
  
  if ~isfield(params,'score_name')
    params.score_name = 'score';
  end
  
  if ~isfield(params,'do_clip')
    params.do_clip = true;
  end

  % Load detections, run NMS and prepare input for evaluation
  globals;
  overlap = 0.5;
  dir_name = fullfile(cachedir,'detections', [experiment_name '_' experiment_name_suffix]);
  cnt = 0;
  
  
  % Avoid duplicate images, because evaluation penalizes for duplicate
  % detections
  for i = 1:length(test)
    tnames{i} = test(i).im;
  end
  [names,uids,b] = unique(tnames);
  
  
  for i = 1:length(uids)
    fprintf('Reading detections for %d image.\n',i)
    ttest = test(uids(i));
    im = imread(ttest.im);
    [ymx,xmx,c] = size(im);
    load(fullfile(dir_name, [num2str(uids(i)) '_boxes.mat']))
    detection = nms(detection,overlap,params,xmx,ymx);
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
  result = eval_detection(test,detections,params);
