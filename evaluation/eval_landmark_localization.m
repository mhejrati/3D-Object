function result = eval_landmark_localization(test_set,detections,model, params)
  if length(test_set)~=length(detections)
    result = [];
    return
  end
  
  if nargin<4
    params = [];
  end
  
  if isempty(params)
    h = figure;
    params.figure = h;
    params.color = 'b';
    params.thresh = .5;
  else
    try
      figure(params.figure);
    catch
      h = figure;
      params.figure = h;
    end
    try
      c = params.color;
    catch
      c = 'b';
      params.color = c;
    end
    try
      thresh = params.thresh;
    catch
      params.thresh = .5;
    end
  end
  
  ntest = length(test_set);
  cnt = 1;
  for i = 1:ntest
    tdetection = detections(i);
    npoints = length(tdetection.filterid);
    t_visibility = [];
    t_gt_point = zeros(npoints,2);
    t_gt_visibility = [];
    for j = 1:npoints
      t_part_name = model.filters(tdetection.filterid(j)).name;
      t_visibility(j) = model.filters(tdetection.filterid(j)).visibility;
      
      t_id = find(strcmp(t_part_name,test_set(i).part_names));
      t_gt_point(j,1:2) = test_set(i).point(t_id,1:2);
      t_gt_visibility(j) = test_set(i).visibility(t_id);
    end


    t_point = tdetection.point(:,1:2);
    points(cnt:cnt+npoints-1,:) = t_point;
    gt_points(cnt:cnt+npoints-1,:) = t_gt_point;
    
    visibility(cnt:cnt+npoints-1) = t_visibility;
    gt_visibility(cnt:cnt+npoints-1) = t_gt_visibility;
    part_size(cnt:cnt+npoints-1) = test_set(i).part_size;    
    
    cnt = cnt+npoints;
  end
  
  dists = sum(((points-gt_points)./repmat(part_size',[1 2])).^2,2);
  
  % Landmark Localization error for all points
  subplot(1,3,1)
  hold on;
  [s_dists,s_ids] = sort(dists);
  tmp_id = find(s_dists>2,1,'first');
  plot(s_dists(1:tmp_id),(1:tmp_id)/length(dists),'color',params.color);
  axis([0 2 0 1]);
  title('All Parts Landmark Localization Error');
  result.all_parts_err_curve = [s_dists(1:tmp_id) (1:tmp_id)'/length(dists)];
  result.all_parts_err = sum(dists<params.thresh)/length(dists);
  grid on;
  xlabel 'error'
  ylabel 'percentage'
  
  % Landmark Localization error for visible points
  subplot(1,3,2)
  hold on;
  tdists = dists(gt_visibility==1);
  [s_dists,s_ids] = sort(tdists);
  tmp_id = find(s_dists>2,1,'first');
  plot(s_dists(1:tmp_id),(1:tmp_id)/length(tdists),'color',params.color);
  axis([0 2 0 1]);
  title('Visible Parts Landmark Localization Error');
  result.visible_parts_err_curve = [s_dists(1:tmp_id) (1:tmp_id)'/length(tdists)];
  result.visible_parts_err = sum(tdists<params.thresh)/length(tdists);
  grid on;
  xlabel 'error'
  ylabel 'percentage'
  
  % Landmark Localization error for visible points
  subplot(1,3,3)
  hold on;
  tdists = dists(gt_visibility~=1);
  [s_dists,s_ids] = sort(tdists);
  tmp_id = find(s_dists>2,1,'first');
  plot(s_dists(1:tmp_id),(1:tmp_id)/length(tdists),'color',params.color);
  axis([0 2 0 1]);
  title('Occluded Parts Landmark Localization Error');
  result.occluded_parts_err_curve = [s_dists(1:tmp_id) (1:tmp_id)'/length(tdists)];
  result.occluded_parts_err = sum(tdists<params.thresh)/length(tdists);
  grid on;
  xlabel 'error'
  ylabel 'percentage'
  
  