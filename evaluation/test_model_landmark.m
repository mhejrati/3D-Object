function test_model_landmark(model_2d, model_3d, test, ...
                                    experiment_name, experiment_name_suffix)
  
  globals;
  dir_name = fullfile(cachedir,'detections_given_bbox', [experiment_name '_' experiment_name_suffix]);
  mkdir(dir_name)
  model_2d.thresh = -2;
  overlap = .5;
  
  try
    load(fullfile(dir_name,'all_boxes.mat'));
  catch
    n_test = length(test);
    parfor i = 1:n_test
      im = imread(test(i).im);
      fprintf('Testing: %d/%d\n',i,n_test);
      if ~exist(fullfile(dir_name, [num2str(i) '_boxes.mat']),'file')
        detection = detect_object_given_bbox(im, model_2d, model_3d, test(i), overlap);
        my_save(fullfile(dir_name, [num2str(i) '_boxes.mat']),detection);
      end
    end
  end


% Because Matlab is Dumb :D
function my_save(filename, detection)
  save(filename, 'detection');