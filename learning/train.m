function model = train(name, model, pos, neg, warp, iter, C, wpos, maxsize, overlap) 
% model = train(name, model, pos, neg, warp, iter, C, Jpos, maxsize, overlap)
%               1,    2,     3,   4,   5,    6,    7, 8,    9,       10
% Train a structured SVM with latent assignement of positive variables
% pos  = list of positive images with part annotations
% neg  = list of negative images
% warp =1 uses warped positives
% warp =0 uses latent positives
% iter is the number of training iterations
%   C  = scale factor for slack loss
% wpos =  amount to weight errors on positives
% maxsize = maximum size of the training data cache (in GB)
% overlap =  minimum overlap in latent positive search

if nargin < 6
  iter = 1;
end

if nargin < 7
  C = 0.002;
end

if nargin < 8
  wpos = 2;
end

if nargin < 9
  % Estimated #sv = (wpos + 1) * # of positive examples
  % maxsize*1e9/(4*model.len)  = # of examples we can store, encoded as 4-byte floats
  no_sv = (wpos+1) * length(pos);
  %maxsize = 10 * no_sv * 4 * sparselen(model) / 1e9;
  %maxsize = min(max(maxsize,3),6);
  %maxsize = 3; %Uncomment this line to run comfortably on machines with 4GB of memory
  maxsize = 8; %Uncomment this line to run comfortable on machines with 8GB memory
end

fprintf('Using %.1f GB\n',maxsize);

if nargin < 10
  overlap = 0.6;
end

% Vectorize the model
len  = sparselen(model);
nmax = round(maxsize*.25e9/len);

rand('state',0);
globals;

% Define global QP problem
clear global qp;
global qp;
% qp.x(:,i) = examples
% qp.i(:,i) = id
% qp.b(:,i) = bias of linear constraint
% qp.d(i)   = ||qp.x(:,i)||^2
% qp.a(i)   = ith dual variable
qp.x  = zeros(len,nmax,'single');
qp.i  = zeros(5,nmax,'int32');
qp.b  = ones(nmax,1,'single');
qp.d  = zeros(nmax,1,'double');
qp.a  = zeros(nmax,1,'double');
qp.sv = logical(zeros(1,nmax));  
qp.n  = 0;
qp.lb = [];

[qp.w,qp.wreg,qp.w0,qp.noneg] = model2vec(model);
qp.Cpos = C*wpos;
qp.Cneg = C;
qp.w    = (qp.w - qp.w0).*qp.wreg;

for t = 1:iter,
  fprintf('\niter: %d/%d\n', t, iter);
  qp.n = 0;
  if warp > 0
    numpositives = poswarp(name, t, model, pos);
  else
    numpositives = poslatent(name, t, model, pos, overlap);
  end
  
  for i = 1:length(numpositives),
    fprintf('component %d got %d positives\n', i, numpositives(i));
  end
  assert(qp.n <= nmax);
  
  % Fix positive examples as permenant support vectors
  % Initialize QP soln to a valid weight vector
  % Update QP with coordinate descent
  qp.svfix = 1:qp.n;
  qp.sv(qp.svfix) = 1;
  qp_prune();
  qp_opt();
  model = vec2model(qp_w,model);
  model.interval = 2;

  % grab negative examples from negative images
  for i = 1:length(neg),
    fprintf('\n Image(%d/%d)',i,length(neg));
    im  = imread(neg(i).im);
    [box,model] = detect(im, model, -1, [], 0, i, -1);
    fprintf(' #cache+%d=%d/%d, #sv=%d, #sv>0=%d, (est)UB=%.4f, LB=%.4f,',size(box,1),qp.n,nmax,sum(qp.sv),sum(qp.a>0),qp.ub,qp.lb);
    % Stop if cache is full
    if sum(qp.sv) == nmax,
      break;
    end
  end

  % One final pass of optimization
  qp_opt();
  model = vec2model(qp_w(),model);

  fprintf('\nDONE iter: %d/%d #sv=%d/%d, LB=%.4f\n',t,iter,sum(qp.sv),nmax,qp.lb);

  % Compute minimum score on positive example (with raw, unscaled features)
  r = sort(qp_scorepos());
  model.thresh   = r(ceil(length(r)*.05));
  model.interval = 10;
  model.lb = qp.lb;
  model.ub = qp.ub;
  % visualizemodel(model);
  % cache model
  % save([cachedir name '_model_' num2str(t)], 'model');
end
fprintf('qp.x size = [%d %d]\n',size(qp.x));
clear global qp;

% get positive examples by warping positive bounding boxes
% we create virtual examples by flipping each image left to right
function numpositives = poswarp(name, t, model, pos)
  numpos = length(pos);
  warped = warppos(name, model, pos);
  minsize = prod(model.maxsize*model.sbin);

  for i = 1:numpos
    fprintf('%s: iter %d: warped positive: %d/%d\n', name, t, i, numpos);
    %bbox = [pos(i).x1 pos(i).y1 pos(i).x2 pos(i).y2];
    bbox = [pos(i).bbox(1) pos(i).bbox(2) pos(i).bbox(3) pos(i).bbox(4)];
    % skip small examples
    if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
      continue
    end    
    % get example
    im = warped{i};
    feat = features(im, model.sbin);
    qp_poswrite(feat,i,model);
  end
  global qp;
  numpositives = qp.n;
  
function qp_poswrite(feat,id,model)

  len = numel(feat);
  ex.id     = [1 id 0 0 0]';
  ex.blocks = [];
  ex.blocks(end+1).i = model.bias.i;
  ex.blocks(end).x   = 1;
  ex.blocks(end+1).i = model.filters.i;
  ex.blocks(end).x   = feat;
  qp_write(ex);
  

% get positive examples using latent detections
% we create virtual examples by flipping each image left to right
function numpositives = poslatent(name, t, model, pos, overlap)
  globals;
  numpos = length(pos);
  model.interval = 5;
  numpositives = zeros(length(model.components), 1);
  minsize = prod(model.maxsize*model.sbin);
  h = figure;
  for i = 1:numpos
    fprintf('%s: iter %d: latent positive: %d/%d\n', name, t, i, numpos);
    % skip small examples
    skipflag = 0;
    box = pos(i).part_boxes;
    for p = 1:length(box)
      if box(p).skip
          continue;
      end
      bbox = box(p).bbox;
      if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
        skipflag = 1;
        break;
      end
    end
    if skipflag
      continue;
    end
    
    % get example
    im = imread(pos(i).im);
    [im, box] = croppos(im, box);
    [detections,foo1,foo2] = detect(im, model, 0, box, overlap, i, 1);
    if ~isempty(detections),
      fprintf(' (comp=%d,sc=%.3f)\n',detections(1).component,detections(1).score);
      c = detections(1).component;
      numpositives(c) = numpositives(c)+1;
      visualize_detected_landmarks(im, model, detections(1),h)
      %ims = sprintf('%s%s_%d_%d.jpg',cachedir,name,i,t); %print(ims,'-djpeg');
    end
  end

% Compute score (weights*x) on positives examples (see qp_write.m)
% Standardized QP stores w*x' where w = (weights-w0)*r, x' = c_i*(x/r)
% (w/r + w0)*(x'*r/c_i) = (v + w0*r)*x'/ C
function scores = qp_scorepos
  global qp;
  y = qp.i(1,1:qp.n);
  I = find(y == 1);
  w = qp.w + qp.w0.*qp.wreg;
  scores = score(w,qp.x,I) / qp.Cpos;

% Computes expected number of nonzeros in sparse feature vector 
function len = sparselen(model)

  len       = 0;
  numblocks = 0;
  for c = 1:length(model.components),
    feat = zeros(model.len,1);
    for p = model.components{c},
      if ~isempty(p.biasid)
        x = model.bias(p.biasid(1));
        i1 = x.i;
        i2 = i1 + numel(x.w) - 1;
        feat(i1:i2) = 1;
        numblocks = numblocks + 1;
      end
      if ~isempty(p.defid)
        x  = model.defs(p.defid(1));
        i1 = x.i;
        i2 = i1 + numel(x.w) - 1;
        feat(i1:i2) = 1;
        numblocks = numblocks + 1;
      end
      if ~isempty(p.filterid)
        x  = model.filters(p.filterid(1));
        i1 = x.i;
        i2 = i1 + numel(x.w) - 1;
        feat(i1:i2) = 1;
        numblocks = numblocks + 1;
      end
    end
    
    % Number of entries needed to encode a block-sparse representation
    %   1 + numberofblocks*2 + #nonzeronumbers
    n = 1 + numblocks*2 + sum(feat);
    len = max(len,n);
  end

% [newim, newbox] = croppos(im, box)
% Crop positive example to speed up latent search.
function [im, box] = croppos(im, box)
    P = length(box);
    x1 = zeros(1,P);
    y1 = zeros(1,P);
    x2 = zeros(1,P);
    y2 = zeros(1,P);
    for p = 1:P
      x1(p) = box(p).bbox(1);
      y1(p) = box(p).bbox(2);
      x2(p) = box(p).bbox(3);
      y2(p) = box(p).bbox(4);
    end
    x1 = min(x1); y1 = min(y1); x2 = max(x2); y2 = max(y2);
    pad = 0.5*((x2-x1+1)+(y2-y1+1));
    x1 = max(1, round(x1-pad));
    y1 = max(1, round(y1-pad));
    x2 = min(size(im,2), round(x2+pad));
    y2 = min(size(im,1), round(y2+pad));

    im = im(y1:y2, x1:x2, :);
    for p = 1:P
      box(p).bbox([1 3]) = box(p).bbox([1 3]) - x1 + 1;
      box(p).bbox([2 4]) = box(p).bbox([2 4]) - y1 + 1;
    end