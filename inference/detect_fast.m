% [boxes,model,ex] = detect_fast(im, model, thresh)
% Detect objects in image using a model and a score threshold.
% Higher threshold leads to fewer detections.

function detections = detect_fast(im, model, thresh)
  % Compute the feature pyramid and prepare filter
  pyra     = featpyramid(im,model);
  interval = model.interval;
  levels   = 1:length(pyra.feat);

  % Cache various statistics derived from model
  [components,filters,resp] = modelcomponents(model,pyra);
  max_detection_num = 10000000;
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

      [Y,X] = find(rscore >= thresh);
      % Walk back down tree following pointers
      % (DEBUG) Assert extracted feature re-produces score
      for i = 1:length(X)
        x = X(i);
        y = Y(i);
        k = Ik(y,x);
        [box,filterids] = backtrack( x , y , k, parts , pyra);
        cnt = cnt + 1;
        assert(cnt<max_detection_num);
        detections(cnt).part_boxes = box;
        detections(cnt).filterid = filterids;
        detections(cnt).component = c;
        detections(cnt).score = rscore(y,x);
      end
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

% Backtrack through dynamic programming messages to estimate part locations
% and the associated feature vector  
function [box,filterids] = backtrack(x,y,mix,parts,pyra)
  numparts = length(parts);
  ptr = zeros(numparts,3);
  box = zeros(numparts,4);
  k   = 1;
  p   = parts(k);
  ptr(k,:) = [x y mix];
  scale = pyra.scale(p.level);
  x1  = (x - 1 - pyra.padx)*scale+1;
  y1  = (y - 1 - pyra.pady)*scale+1;
  x2  = x1 + p.sizx(mix)*scale - 1;
  y2  = y1 + p.sizy(mix)*scale - 1;
  box(k,:) = [x1 y1 x2 y2];
  filterids(k) = parts(k).filterid(ptr(k,3));
  for k = 2:numparts,
    p   = parts(k);
    par = p.parent;
    x   = ptr(par,1);
    y   = ptr(par,2);
    mix = ptr(par,3);
    ptr(k,1) = p.Ix(y,x,mix);
    ptr(k,2) = p.Iy(y,x,mix);
    ptr(k,3) = p.Ik(y,x,mix);
    scale = pyra.scale(p.level);
    x1  = (ptr(k,1) - 1 - pyra.padx)*scale+1;
    y1  = (ptr(k,2) - 1 - pyra.pady)*scale+1;
    x2  = x1 + p.sizx(ptr(k,3))*scale - 1;
    y2  = y1 + p.sizy(ptr(k,3))*scale - 1;
    box(k,:) = [x1 y1 x2 y2];
    filterids(k) = parts(k).filterid(ptr(k,3));
  end

% Compute the deformation feature given parent locations, 
% child locations, and the child part
function res = defvector(px,py,x,y,mix,par_mix,part)
  probex = ( (px-1)*part.step + part.startx(par_mix,mix) );
  probey = ( (py-1)*part.step + part.starty(par_mix,mix) );
  dx  = probex - x;
  dy  = probey - y;
  res = -[dx^2 dx dy^2 dy]';

% Compute a mask of filter reponse locations (for a filter of size sizy,sizx)
% that sufficiently overlap a ground-truth bounding box (bbox) 
% at a particular level in a feature pyramid
function ov = testoverlap(sizx,sizy,pyra,level,bbox,overlap)
  scale = pyra.scale(level);
  padx  = pyra.padx;
  pady  = pyra.pady;
  [dimy,dimx,foo] = size(pyra.feat{level});
  
  bx1 = bbox(1);
  by1 = bbox(2);
  bx2 = bbox(3);
  by2 = bbox(4);
  
  % Index windows evaluated by filter (in image coordinates)
  x1 = ((1:dimx-sizx+1) - padx - 1)*scale + 1;
  y1 = ((1:dimy-sizy+1) - pady - 1)*scale + 1;
  x2 = x1 + sizx*scale - 1;
  y2 = y1 + sizy*scale - 1;
  
  % Compute intersection with bbox
  xx1 = max(x1,bx1);
  xx2 = min(x2,bx2);
  yy1 = max(y1,by1);
  yy2 = min(y2,by2);
  w   = xx2 - xx1 + 1;
  h   = yy2 - yy1 + 1;
  w(w<0) = 0;
  h(h<0) = 0;
  inter  = h'*w;
  
  % area of (possibly clipped) detection windows and original bbox
  area = (y2-y1+1)'*(x2-x1+1);
  box  = (by2-by1+1)*(bx2-bx1+1);
  
  % thresholded overlap
  ov   = inter ./ (area + box - inter) > overlap;