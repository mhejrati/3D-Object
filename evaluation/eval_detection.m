function result = eval_detection(test_set,detections,params)
  try
    min_overlap = params.min_overlap;
  catch
    min_overlap = 0.5;
  end
  
  % Initialize and index all the test instances
  npos = length(test_set);
  detected = false(1,npos);
  for i = 1:npos
    [pathstr, name, ext, versn] = fileparts(test_set(i).im);
    gt_names{i} = name;
  end
  
  hash = VOChash_init(unique(gt_names));
  for i = 1:npos
    ind = VOChash_lookup(hash,gt_names{i});
    gt_ids(i) = ind;
  end

  % Sort all detections
  n_det = length(detections);
  for i = 1:n_det
    [pathstr, name, ext, versn] = fileparts(detections(i).im);
    det_names{i} = name;
    sc(i) = detections(i).score;
    ind = VOChash_lookup(hash,det_names{i});
    det_ids{i} = ind;
  end
  [sc,si] = sort(sc,'descend');
  det_names = det_names(si);
  det_ids = det_ids(si);
  detections = detections(si);
  
  % Loop over detections and assign true false detection labels
  tp=zeros(n_det,1);
  fp=zeros(n_det,1);
  tic;
  
  for d=1:n_det
    % display progress
    if toc>1
        fprintf('pr: compute: %d/%d\n',d,n_det);
        drawnow;
        tic;
    end
    
    % find ground truth image
    i=det_ids{d};
    if isempty(i)
      fp(d)=1;
      fprintf('%s : Unrecognized image, counted as negative\n',det_names{d});
      continue;
    end

    % assign detection to ground truth object if any
    bb=detections(d).box;
    ovmax=-inf;
    tmp_gt_ids = find(gt_ids == i);
    for j=1:length(tmp_gt_ids)
        bbgt=test_set(tmp_gt_ids(j)).box;
        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
        iw=bi(3)-bi(1)+1;
        ih=bi(4)-bi(2)+1;
        if iw>0 & ih>0                
            % compute overlap as area of intersection / area of union
            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
               (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
               iw*ih;
            ov=iw*ih/ua;
            if ov>ovmax
                ovmax=ov;
                jmax=j;
            end
        end
    end
    % assign detection as true positive/don't care/false positive
    if ovmax>=min_overlap
      if ~detected(tmp_gt_ids(jmax))
        tp(d)=1;            % true positive
        detected(tmp_gt_ids(jmax))=true;
      else
        fp(d)=1;            % false positive (multiple detection)
      end
    else
        fp(d)=1;                    % false positive
    end
  end

  % Compile results
  fp=cumsum(fp);
  tp=cumsum(tp);
  rec=tp/npos;
  prec=tp./(fp+tp);
  ap=VOCap(rec,prec);
  
  result.fp = fp;
  result.tp = tp;
  result.rec = rec;
  result.prec = prec;
  result.ap = ap;
  
  try
    draw = params.draw;
  catch
    draw = true;
  end
  
  if draw
    try
    	figure(params.figure);
    catch
      h = figure;
      result.figure = h;
    end
    try
      c = params.color;
    catch
      c = 'b';
    end
    % plot precision/recall
    hold on;
    plot(rec,prec,'-','color',c);
    grid on;
    xlabel 'recall'
    ylabel 'precision'
    axis([0 1 0 1]);
  end
  
  
% Code from VOC PASCAL 2012 Development kit  
function ap = VOCap(rec,prec)

  mrec=[0 ; rec ; 1];
  mpre=[0 ; prec ; 0];
  for i=numel(mpre)-1:-1:1
    mpre(i)=max(mpre(i),mpre(i+1));
  end
  i=find(mrec(2:end)~=mrec(1:end-1))+1;
  ap=sum((mrec(i)-mrec(i-1)).*mpre(i));

% Code from VOC PASCAL 2012 Development kit
function hash = VOChash_init(strs)

  hsize=100000;
  hash.key=cell(hsize,1);
  hash.val=cell(hsize,1);

  for i=1:numel(strs)
      s=strs{i};
      h=mod(str2double(s([3:4 6:11 13:end])),hsize)+1;
      j=numel(hash.key{h})+1;
      hash.key{h}{j}=strs{i};
      hash.val{h}(j)=i;
  end

% Code from VOC PASCAL 2012 Development kit
function ind = VOChash_lookup(hash,s)

  hsize=numel(hash.key);
  h=mod(str2double(s([3:4 6:11 13:end])),hsize)+1;
  ind=hash.val{h}(strmatch(s,hash.key{h},'exact'));