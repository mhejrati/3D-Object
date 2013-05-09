% --------------------
% specify model parameters
% number of mixtures for 26 parts
clear
suffix = 'test9';
% Tree structure for 26 parts: pa(i) is the parent of part i
% This structure is implicity assumed during data preparation
% (PARSE_data.m) and evaluation (PARSE_eval_pcp)

load CAR/2011annotations.mat;
load CAR/2011pascal_car.mat;

% Spatial resolution of HOG cell, interms of pixel width and hieght
% The PARSE dataset contains low-res people, so we use low-res parts
sbin = 4;


% --------------------
% Prepare training and testing images and part bounding boxes
% You will need to write custom IMAGE_data() functions for your dataset
globals;

name = 'CAR';
%transformation = [1:20];  % checked
%[tpos ttest tneg] = CAR_data(pos,neg,annotations,transformation);   % checked
%tpos        = CAR_pointtobox(tpos);  % checked

%[parts,pa,colorset,transformation] = learn_tree();  % checked
[pos test neg] = CAR_data(pos,neg,annotations); % checked
pos        = CAR_pointtobox(pos);  % checked


% Debug
%pos = pos(1:50);
%neg = neg(1:20);
% test = test(1:10);
% --------------------
% training
%model = trainmodel(name,pos,neg,K,pa,sbin,suffix,colorset,parts);
model = trainmodel_clean(name,pos,neg,sbin,suffix);



% --------------------
% testing
%model.thresh   = min(model.thresh,-2);
%model.thresh   = -1;

%model = add_valid_combinations(model,pa);
detections = testmodel_pops(model)
[detections] = testmodel(name,model,test,suffix,'res');
% --------------------
% evaluation
% You will need to write your own evaluation code for your dataset
pcp = test_pcp_given_bbox(name, model, test, suffix);
%[detRate PCP R] = CAR_eval_pcp(name,points,test);
fprintf('detRate=%.3f, PCP=%.3f, detRate*PCP=%.3f\n',detRate,PCP,detRate*PCP);
%save([cachedir name '_pcp_' suffix],'detRate','PCP','R');
% --------------------
% visualization
% figure(1);
% visualizemodel(model);
% figure(2);
% visualizeskeleton(model);
% 
for i = 20:40
    demoimid = i;
    box = boxes{demoimid}(1,:);
    if isempty(box)
        continue;
    end
    h = figure(i+2);
    im  = imread(test(demoimid).im);
    
    mixs = mixtures{demoimid}(1,:);
    %showboxes(im,box,colorset,mixs);
    showboxes(im,box,model,mixs);
    %saveas(h,['result' num2str(i) '.jpg'])
    
    %subplot(1,2,2); showskeleton(im,box,colorset,model.components{1});
end