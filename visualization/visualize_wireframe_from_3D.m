function d = visualize_wireframe_from_3D(detection, model, wireframe, params)

  hold on;
  edges = wireframe.edges;
  c = params.color;
  
  for i = 1:length(detection.filterid)
    x(i) = detection.point_3D(i,1);
    y(i) = detection.point_3D(i,2);
    part_names{i} = model.filters(detection.filterid(i)).name;
  end

  for i = 1:size(edges,1)
    p1 = strmatch(edges{i,1},part_names);
    p2 = strmatch(edges{i,2},part_names);
    p  = [p1 p2];
    plot(x(p),y(p),'linewidth',2,'Color',c);
    td(i) = norm([x(p1)-x(p2) y(p1)-y(p2)]);
  end

  xm = mean(x);
  ym = mean(y);
  xv = (detection.rotation*[20 0 0]')';
  yv = (detection.rotation*[0 20 0]')';
  zv = (detection.rotation*[0 0 20]')';

  plot([xm xm+xv(1)] ,[ym ym+xv(2)],'linewidth',4,'Color','r');
  plot([xm xm+yv(1)] ,[ym ym+yv(2)],'linewidth',4,'Color','g');
  plot([xm xm+zv(1)] ,[ym ym+zv(2)],'linewidth',4,'Color','b');

  d = mean(td);

  drawnow;
