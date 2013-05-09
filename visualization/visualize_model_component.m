function visualize_model_component(model,global_mixture_id,h)
  if nargin<3
    h = figure;
  end
  pad = 2;
  bs = 20;
  c = model.components{global_mixture_id};
  n_parts = length(c);
  
  % Find the configuration with largest sum of biases (most likely
  % configuration), and the associated filter ids and deformation ids
  local_mixture_ids = find_local_mixture_ids(model,c);
  
  % Draw the model
  part = c(1);
  % part filter
  w = model.filters(part.filterid(local_mixture_ids(1))).w;
  w = foldHOG(w);
  scale = max(abs(w(:)));
  p = HOGpicture(w, bs);
  p = padarray(p, [pad pad], 0);
  p = uint8(p*(255/scale));    
  % border 
  p(:,1:2*pad) = 128;
  p(:,end-2*pad+1:end) = 128;
  p(1:2*pad,:) = 128;
  p(end-2*pad+1:end,:) = 128;
  im = p;
  startpoint = zeros(n_parts,2);
  startpoint(1,:) = [0 0];

  for k = 2:n_parts
      part = c(k);
      parent = c(k).parent;

      fi = local_mixture_ids(k);
      pi = local_mixture_ids(parent);

      % part filter
      w = model.filters(part.filterid(fi)).w;
      w = foldHOG(w);
      scale = max(abs(w(:)));
      p = HOGpicture(w, bs);
      p = padarray(p, [pad pad], 0);
      p = uint8(p*(255/scale));    
      % border 
      p(:,1:2*pad) = 128;
      p(:,end-2*pad+1:end) = 128;
      p(1:2*pad,:) = 128;
      p(end-2*pad+1:end,:) = 128;

      % paste into root
      def = model.defs(part.defid(pi,fi));

      x1 = (def.anchor(1)-1)*bs+1 + startpoint(parent,1);
      y1 = (def.anchor(2)-1)*bs+1 + startpoint(parent,2);

      [H W] = size(im);
      imnew = zeros(H + max(0,1-y1), W + max(0,1-x1));
      imnew(1+max(0,1-y1):H+max(0,1-y1),1+max(0,1-x1):W+max(0,1-x1)) = im;
      im = imnew;

      startpoint = startpoint + repmat([max(0,1-x1) max(0,1-y1)],[n_parts,1]);

      x1 = max(1,x1);
      y1 = max(1,y1);
      x2 = x1 + size(p,2)-1;
      y2 = y1 + size(p,1)-1;

      startpoint(k,1) = x1 - 1;
      startpoint(k,2) = y1 - 1;
      
      im(y1:y2, x1:x2) = p;
  end

  % plot parts   
  imagesc(im); colormap gray; axis equal; axis off; drawnow;