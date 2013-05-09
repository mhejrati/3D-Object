  % Visualize local mixture clustering
  % visualize_local_clusters(objects,local_ids,part_id)
  
  function visualize_local_clusters(pos,local_ids,part_id)
  n_clusters = max(local_ids{part_id});
  for i = 1:n_clusters
    tmp_ids = find(local_ids{part_id}==i);
    montage_im = zeros(100,100,3,length(tmp_ids));
    for j = 1:length(tmp_ids)
      id = tmp_ids(j);
      im = imread(pos(id).im);
      x1 = max(pos(id).x1(part_id),1);
      y1 = max(pos(id).y1(part_id),1);
      x2 = min(pos(id).x2(part_id),size(im,2));
      y2 = min(pos(id).y2(part_id),size(im,1));
      tim = im(y1:y2,x1:x2,:);
      tim2 = 255*ones(size(tim,1)+2,size(tim,2)+2,3);
      tim2(2:size(tim,1)+1,2:size(tim,2)+1,:) = tim;
      tim2 = padarray(tim2,[2 2]);
      montage_im(:,:,:,j) = imresize(tim2,[100 100]);
    end
    if length(tmp_ids)>0
      figure;
      montage(double(montage_im)/255)
    end
  end