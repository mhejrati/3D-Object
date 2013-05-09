% Set up global variables used throughout the code
addpath learning;
addpath inference;
addpath evaluation;
addpath sfm;
addpath visualization;
addpath data;

% directory for caching models, intermediate data, and results
cachedir = 'cache/';
if ~exist(cachedir,'dir')
    unix(['mkdir ' cachedir]);
end

% directory with PASCAL VOC development kit and dataset
VOCyear = '2011';
VOCdevkit = '~/data/VOC/VOC2011/VOCdevkit/';
VOC_images_path = '~/data/VOC/VOC2011/VOCdevkit/VOC2011/JPEGImages/';
VOCdevkit2007=false;