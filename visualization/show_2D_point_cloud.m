% Overlay 2D point cloud on an image
% show_2D_point_cloud(im, points, colors, names, do_fill, h)

% im     : is the image matrix
% points : an nx2 matrix of x,y locations of points
% colors : an nx3 martix of colors for each point
% names  : names for each point
% do_fill: if show the point using a filled circle or not, used to
%          differentiate between visibile and occluded parts
% h      : handle to figure, if empty it opens a new figure

function show_2D_point_cloud(im, points, colors, names, do_fill, h)
% Show detected boxes for a detection
n_points = size(points,1);
if nargin<6
  h = figure;
end
if isempty(h)
  h = figure;
end

if nargin<5
  do_fill = true(n_points,1);
end
if isempty(do_fill)
  do_fill = true(n_points,1);
end

if nargin<4
  names = cell(n_points,1);
end
if isempty(names)
  names = cell(n_points,1);
end

if nargin<3
  colors = hsv(n_points);
end
if isempty(colors)
  colors = hsv(n_points);
end

clf(h);

imagesc(im); axis image; axis off;
hold on

point_size = (max(points(:,1)) - min(points(:,1)))/2;
for i = 1:n_points
  if do_fill(i)
    scatter(points(i,1),points(i,2),point_size,colors(i,:),'filled');
  else
    scatter(points(i,1),points(i,2),point_size,colors(i,:));
  end
  if ~isempty(names{i})
    text(points(i,1),points(i,2),names{i},'BackgroundColor',colors(i,:),'FontSize',8)
  end
end
drawnow;
