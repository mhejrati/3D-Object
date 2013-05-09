% 
% Demo learning, detection, evaluation and visualization

% ---------------
% Set basic and global settings, compile mex sources
clear all
close all
globals
compile


% ---------------
% Specify the model settings
n_local_mixture = 5;            % Number of filters per part
n_global_mixture = 50;          % Number of global mixtures for model
n_3d_basis = 5;                 % Number of 3D basis shapes
hog_sbin = 4;
experiment_name = '3DCars';     % Used to name temp files and results
experiment_name_suffix = ['n_local:' num2str(n_local_mixture) '_n_global:' num2str(n_global_mixture)];
%experiment_name_suffix = 'run1';



% ---------------
% Read data and prepare training and testing images and part bounding boxes
dataset_file_path = './data/3DCar.mat';
pascal_annotation_path = './data/2011PASCAL_CAR.mat';
[pos test neg] = read_data(dataset_file_path,VOC_images_path);

% visualize an example of 2D landmark annotation, good for debugging
% visualize_landmark_annotation(pos(1))


% ---------------
% Debug mode : use subset of images
run_debug = false;
n_train = 50;
n_test = 10;
if run_debug  
  n_local_mixture = 2;
  n_global_mixture = 5;
  pos = pos(1:n_train);
  neg = neg(1:n_train);
  test = test(1:n_test);
  experiment_name_suffix = 'debug';
end


% ---------------
% Training

% Train 2D model
model_2d = train_model(pos, neg, hog_sbin, n_local_mixture, n_global_mixture,...
                    experiment_name, experiment_name_suffix);

% Train 3D model
[model_3d, pos, test] = train_3d_model(pos, test, n_3d_basis, experiment_name, experiment_name_suffix);


% ---------------
% Visualize model

% Visualize 2D model
visualize_model(model_2d)

% Visualize 3D model
wireframe = wireframe_car();
visualize_3D_basis_shapes(model_3d, wireframe)


% ---------------
% Testing
model_2d.thresh = -1;
detections = test_model(model_2d, model_3d, test, experiment_name, experiment_name_suffix);


% ---------------
% Evaluation

% Evaluate 2D bounding bounding box detection using VOC PASCAL object
% detection challenge method
[ap precision recall] = evaluate_2D_box_detection(test,model,detections,experiment_name);

% Evaluate 2D landmark localization and visibility prediction

% Evaluate viewpoint estimation


