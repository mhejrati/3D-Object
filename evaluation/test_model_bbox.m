function test_model_bbox(model_2d, model_3d, test, ...
                                    experiment_name, experiment_name_suffix)
  
  globals;
  dir_name = fullfile(cachedir,'detections', [experiment_name '_' experiment_name_suffix]);
  mkdir(dir_name)
  try
    load(fullfile(dir_name,'all_boxes.mat'));
  catch
    n_test = length(test);
    parfor i = 1:n_test
      im = imread(test(i).im);
      fprintf('Testing: %d/%d\n',i,n_test);
      if ~exist(fullfile(dir_name, [num2str(i) '_boxes.mat']),'file')
        detection = detect_object(im, model_2d, model_3d, model_2d.thresh);    
        my_save(fullfile(dir_name, [num2str(i) '_boxes.mat']),detection);
      end
    end
%    detections = aggregate_detections(dir_name, n_test);
  end

% Because Matlab is Dumb :D  
function detections = aggregate_detections(dir_name, n_test)
  detections = cell(1,n_test);
  for i = 1:n_test
    fprintf('Testing: %d/%d\n',i,n_test);
    load(fullfile(dir_name, [num2str(i) '_boxes.mat']))
    detections{i} = detection;
  end
  save(fullfile(dir_name,'all_boxes.mat'),'-v7.3', 'detections');
  
% Because Matlab is Dumb :D
function my_save(filename, detection)
  save(filename, 'detection');