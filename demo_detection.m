% 
% Demo detection

% Set basic and global settings
clear all
close all
globals
compile
overlap = .5;

% Load pre-computed model
load('model')
model_2d.thresh = -1;

% Visualize 2D model
visualize_model(model_2d)

% Visualize 3D model
wireframe = wireframe_car();
visualize_3D_basis_shapes(model_3d, wireframe)

% Load image and run detection
im = imread('car.png');
[ymx,xmx,c] = size(im);

model_2d.interval = 10;
detection = detect_object(im, model_2d, model_3d, model_2d.thresh);
detection = nms(detection,overlap,xmx,ymx);
visualize_detected_landmarks(im, model_2d, detection(1))