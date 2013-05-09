% Visualize 2D landmark localization model
% visualize_model(model)

function visualize_model(model)
  h = figure;
  n_global_mixtures = length(model.components);
  for i = 1:length(model.components)
    subplot(ceil(sqrt(n_global_mixtures)),ceil(sqrt(n_global_mixtures)),i);
    visualize_model_component(model,i,h);
  end