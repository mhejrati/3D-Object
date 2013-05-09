% Read and prepare train and test dataset. This function is dataset 
% specific, you need to modify the code for other datasets.
% [pos test neg] = read_data(dataset_file_path,pascal_annotation_path,images_path)

% The data format for the code is as follows
%   pos:
%     object(i).im: filename for the image containing i-th object
%     object(i).point: 2D part locations for the i-th object
%     object(i).part_size: size of the parts for the i-th object (in pixels)
%     object(i).pascal_box: PASCAL VOC bounding box for the i-th object, you
%               dont need it excpet for evaluation with PASCAL VOC method
%     object(i).box: bounding box for the i-th object
%     object(i).visibility: the visibility type of each part for the i-th
%               object. (1: Visible, 2: Truncated outside image, 3: Occluded)
%     object(i).part_names
% This function also prepares flipped images for training.

function [pos test neg] = read_data(dataset_file_path,images_path)
%load(pascal_annotation_path)
load(dataset_file_path)

pos = point_to_box(pos);
for i = 1:length(pos)
  im_path = fullfile(images_path, pos(i).im);
  pos(i).im = im_path;
end

test = point_to_box(test);
for i = 1:length(test)
  im_path = fullfile(images_path, test(i).im);
  test(i).im = im_path;
end

for i = 1:length(neg)
  im_path = fullfile(images_path, neg(i).im);
  neg(i).im = im_path;
end

