% [boxes,model] = detect_fast(im, model, thresh)
% Detect objects in image using a model and a score threshold.
% Higher threshold leads to fewer detections.

function detections = detect_fast(im, model, thresh, just_max)
  if nargin < 4
    just_max = false;
  end
  % Compute the feature pyramid and prepare filter
  pyra     = featpyramid(im,model);
  interval = model.interval;
  levels   = 1:length(pyra.feat);

  % Cache various statistics derived from model
  [components,filters,resp] = modelcomponents(model,pyra);
  max_detection_num = 100000;
  detections = struct('filterid',num2cell(zeros(max_detection_num,1)),'part_boxes',{0},'component',{0},'score',{0});
  cnt        = 0;

  % Iterate over random permutation of scales and components,
  for rlevel = levels,
    % Iterate through mixture components
    for c  = randperm(length(model.components)),
      parts    = components{c};
      numparts = length(parts);

      % Local scores
      for k = 1:numparts,
        f     = parts(k).filterid;
        level = rlevel-parts(k).scale*interval;
        if isempty(resp{level}),
          resp{level} = fconv(pyra.feat{level},filters,1,length(filters));
        end
        for fi = 1:length(f)
          parts(k).score(:,:,fi) = resp{level}{f(fi)};
        end
        parts(k).level = level;
      end

      % Walk from leaves to root of tree, passing message to parent
      for k = numparts:-1:2,
        par = parts(k).parent;
        [msg,parts(k).Ix,parts(k).Iy,parts(k).Ik] = passmsg(parts(k),parts(par));
        parts(par).score = parts(par).score + msg;
      end

      % Add bias to root score
      parts(1).score = parts(1).score + parts(1).b;
      [rscore Ik]    = max(parts(1).score,[],3);
      
      % If just_max=True then just consider local maxima scores
      if just_max
        h = fspecial('gaussian', 4, 4);
        [Y,X] = find(imregionalmax(imfilter(rscore,h,'same'),8) & (rscore >= thresh));
      else
        [Y,X] = find(rscore >= thresh);
      end
      
      if length(X) > 0,
        I   = (X-1)*size(rscore,1) + Y;
        box = backtrack(X,Y,Ik(I),parts,pyra);
        for i = 1:length(X)
          cnt = cnt + 1;
          if cnt>length(detections)
            detections(cnt+max_detection_num) = detections(1);
          end
          tmp_box = reshape(box(i,setdiff([1:size(box,2)],[5:5:size(box,2)])),[4,size(box,2)/5]);
          tmp_ids = box(i,[5:5:size(box,2)]);
          detections(cnt).part_boxes = tmp_box';
          detections(cnt).filterid = tmp_ids;
          detections(cnt).component = c;
          detections(cnt).score = rscore(I(i));
        end
        fprintf('%d detection processed at level=%d and c=%d \n',cnt,rlevel,c);
      end
      
%       % Walk back down tree following pointers
%       for i = 1:length(X)
%         x = X(i);
%         y = Y(i);
%         k = Ik(y,x);
%         [box,filterids] = backtrack( x , y , k, parts , pyra);
%         cnt = cnt + 1;
%         if cnt>length(detections)
%           detections(cnt+max_detection_num) = detections(1);
%         end
%         assert(cnt<=length(detections));
%         detections(cnt).part_boxes = box;
%         detections(cnt).filterid = filterids;
%         detections(cnt).component = c;
%         detections(cnt).score = rscore(y,x);
%       end
    end
  end

  detections = detections(1:cnt);


% ----------------------------------------------------------------------
% Helper functions for detection, feature extraction, and model updating
% ----------------------------------------------------------------------

% Cache various statistics from the model data structure for later use  
function [components,filters,resp] = modelcomponents(model,pyra)
  components = cell(length(model.components),1);
  for c = 1:length(model.components),
    for k = 1:length(model.components{c}),
      p = model.components{c}(k);
      [p.sizy,p.sizx,p.w,p.defI,p.starty,p.startx,p.step,p.level,p.Ix,p.Iy] = deal([]);
      [p.scale,p.level,p.Ix,p.Iy] = deal(0);
 
      % store the scale of each part relative to the component root
      par = p.parent;      
      assert(par < k);
      p.b = [model.bias(p.biasid).w];
      p.b = reshape(p.b,[1 size(p.biasid)]);
      p.biasI = [model.bias(p.biasid).i];
      p.biasI = reshape(p.biasI,size(p.biasid));
      
      for f = 1:length(p.filterid)
        x = model.filters(p.filterid(f));
        [p.sizy(f) p.sizx(f) foo] = size(x.w);
        p.filterI(f) = x.i;
      end
      if length(p.filterid)>1
        p.sizy = p.sizy';
        p.sizx = p.sizx';
        p.filterid = p.filterid';
      end
      
      for par_id = 1:size(p.defid,1)
          for child_id = 1:size(p.defid,2)
            x = model.defs(p.defid(par_id,child_id));
            p.w(:,par_id,child_id)  = x.w';
            p.defI(par_id,child_id) = x.i;
            ax  = x.anchor(1);
            ay  = x.anchor(2);
            ds  = x.anchor(3);
            p.scale = ds + components{c}(par).scale;
            % amount of (virtual) padding to hallucinate
            step     = 2^ds;
            virtpady = (step-1)*pyra.pady;
            virtpadx = (step-1)*pyra.padx;
            % starting points (simulates additional padding at finer scales)
            p.starty(par_id,child_id) = ay-virtpady;
            p.startx(par_id,child_id) = ax-virtpadx;      
            p.step   = step;
          end
      end
      components{c}(k) = p;
    end
  end
  
  resp    = cell(length(pyra.feat),1);
  filters = cell(length(model.filters),1);
  for i = 1:length(filters),
    filters{i} = model.filters(i).w;
  end
  
% Given a 2D array of filter scores 'child',
% (1) Apply distance transform
% (2) Shift by anchor position of part wrt parent
% (3) Downsample if necessary
function [score,Ix,Iy,Ik] = passmsg(child,parent)
  K   = length(child.filterid);
  Ny  = size(parent.score,1);
  Nx  = size(parent.score,2);  
  Ix0 = zeros([Ny Nx K]);
  Iy0 = zeros([Ny Nx K]);
  [Ix0,Iy0,score0] = deal(zeros([Ny Nx K]));


  % At each parent location, for each parent mixture 1:L, compute best child mixture 1:K
  L  = length(parent.filterid);
  N  = Nx*Ny;
  i0 = reshape(1:N,Ny,Nx);
  [score,Ix,Iy,Ix,Ik] = deal(zeros(Ny,Nx,L));
  for l = 1:L
    for k = 1:K
        [score0(:,:,k),Ix0(:,:,k),Iy0(:,:,k)] = shiftdt(child.score(:,:,k), child.w(1,l,k), child.w(2,l,k), child.w(3,l,k), child.w(4,l,k),child.startx(l,k),child.starty(l,k),Nx,Ny,child.step);
    end

    b = child.b(1,l,:);
    [score(:,:,l),I] = max(bsxfun(@plus,score0,b),[],3);
    i = i0 + N*(I-1);
    Ix(:,:,l)    = Ix0(i);
    Iy(:,:,l)    = Iy0(i);
    Ik(:,:,l)    = I;
  end

% % Backtrack through dynamic programming messages to estimate part locations
% % and the associated feature vector  
% function [box,filterids] = backtrack(x,y,mix,parts,pyra)
%   numparts = length(parts);
%   ptr = zeros(numparts,3);
%   box = zeros(numparts,4);
%   k   = 1;
%   p   = parts(k);
%   ptr(k,:) = [x y mix];
%   scale = pyra.scale(p.level);
%   x1  = (x - 1 - pyra.padx)*scale+1;
%   y1  = (y - 1 - pyra.pady)*scale+1;
%   x2  = x1 + p.sizx(mix)*scale - 1;
%   y2  = y1 + p.sizy(mix)*scale - 1;
%   box(k,:) = [x1 y1 x2 y2];
%   filterids(k) = parts(k).filterid(ptr(k,3));
%   for k = 2:numparts,
%     p   = parts(k);
%     par = p.parent;
%     x   = ptr(par,1);
%     y   = ptr(par,2);
%     mix = ptr(par,3);
%     ptr(k,1) = p.Ix(y,x,mix);
%     ptr(k,2) = p.Iy(y,x,mix);
%     ptr(k,3) = p.Ik(y,x,mix);
%     scale = pyra.scale(p.level);
%     x1  = (ptr(k,1) - 1 - pyra.padx)*scale+1;
%     y1  = (ptr(k,2) - 1 - pyra.pady)*scale+1;
%     x2  = x1 + p.sizx(ptr(k,3))*scale - 1;
%     y2  = y1 + p.sizy(ptr(k,3))*scale - 1;
%     box(k,:) = [x1 y1 x2 y2];
%     filterids(k) = parts(k).filterid(ptr(k,3));
%   end
  
  
  % Backtrack through DP msgs to collect ptrs to part locations
function box = backtrack(x,y,mix,parts,pyra)
  numx     = length(x);
  numparts = length(parts);
  
  xptr = zeros(numx,numparts);
  yptr = zeros(numx,numparts);
  mptr = zeros(numx,numparts);
  box  = zeros(numx,5,numparts);

  for k = 1:numparts,
    p   = parts(k);
    if k == 1,
      xptr(:,k) = x;
      yptr(:,k) = y;
      mptr(:,k) = mix;
    else
      par = p.parent;
      [h,w,dummy] = size(p.Ix);
      I   = (mptr(:,par)-1)*h*w + (xptr(:,par)-1)*h + yptr(:,par);
      xptr(:,k) = p.Ix(I);
      yptr(:,k) = p.Iy(I);
      mptr(:,k) = p.Ik(I);
    end
    scale = pyra.scale(p.level);
    x1 = (xptr(:,k) - 1 - pyra.padx)*scale+1;
    y1 = (yptr(:,k) - 1 - pyra.pady)*scale+1;
    x2 = x1 + p.sizx(mptr(:,k))*scale - 1;
    y2 = y1 + p.sizy(mptr(:,k))*scale - 1;
    box(:,:,k) = [x1 y1 x2 y2 p.filterid(mptr(:,k))];
  end
  box = reshape(box,numx,5*numparts);
