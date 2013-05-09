function visualize_3D_point(points,part_names,wireframe,h)
  if nargin<4
    h = figure;
  else
    figure(h);
  end

  hold on;
  edges = wireframe.edges;

  x  = points(1,:);
  y  = points(2,:);
  z  = points(3,:);
  for i = 1:size(edges,1)
      p1 = strmatch(edges{i,1},part_names);
      p2 = strmatch(edges{i,2},part_names);
      p  = [p1 p2];
      plot3(x(p),y(p),z(p));
  end

  % Plot x axis
  plot3([0 100],[0 0],[0 0],'Color','r');
  text(100,0,0,'X','Color','r','FontSize',8)
  % Plot y axis
  plot3([0 0],[0 100],[0 0],'Color','g');
  text(0,100,0,'Y','Color','g','FontSize',8)
  % Plot z axis
  plot3([0 0],[0 0],[0 100],'Color','b');
  text(0,0,100,'Z','Color','b','FontSize',8)

  drawnow;
  grid on;
  view(3);