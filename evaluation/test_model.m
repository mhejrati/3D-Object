function detections = test_model(model_2d, model_3d, test, ...
                                    experiment_name, experiment_name_suffix)
  
  globals;
  dir_name = fullfile(cachedir,'detections', [experiment_name '_' experiment_name_suffix]);
  mkdir(dir_name)
  try
    load(fullfile(dirname,'all_boxes.mat'));
  catch
    n_test = length(test);
    detections = cell(1,n_test);
    
    for i = 1:n_test
      im = imread(test(i).im);
      fprintf('Testing: %d/%d\n',i,n_test);
      try 
        load(fullfile(dir_name, [num2str(i) '_boxes.mat']))
      catch
        detection = detect_object(im, model_2d, model_3d, model_2d.thresh);    
        save(fullfile(dir_name, [num2str(i) '_boxes.mat']), 'detection');
      end
      detections{i} = detection;
    end
    save([cachedir name 'all_boxes_' suffix],'-v7.3', 'detections');
  end