function visualize_3D_basis_shapes(model,wireframe)

  h = figure;
  n_basis = size(model.deformation_shapes,1)/3;
  
  for i = 1:n_basis
    subplot(ceil(sqrt(n_basis)),ceil(sqrt(n_basis)),i);
    tmp_deformation_shape = model.deformation_shapes((i-1)*3+1:i*3,:);
    tmp_points = model.mean_shape + tmp_deformation_shape;
    visualize_3D_point(tmp_points,model.part_names,wireframe,h)
  end
