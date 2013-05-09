function [P3, RO, Tr, Z] = em_sfm_known_shape(P, MD, model, tol, max_em_iter)
%  INPUT:
%
%  P           - (2*T) x J tracking matrix:          P([t t+T],:) contains the 2D projections of the J points at time t
%  MD          - T x J missing data binary matrix:   MD(t, j)=1 if no valid data is available for point j at time t, 0 otherwise
%  K           - number of deformation basis
%  use_lds     - set to 1 to model deformations using a linear dynamical system; set to 0 otherwise
%  tol         - termination tolerance (proportional change in likelihood)
%  max_em_iter - maximum number of EM iterations 
%
%
%  OUTPUT:
%
%  P3          - (3*T) x J 3D-motion matrix:                    ( P3([t t+T
%  RO          - rotation:                 cell array           ( RO{t} gives the rotation matrix at time t )
%  Tr          - translation:              T x 2 matrix
%  Z           - deformation weights:      T x K matrix

  S_bar = model.mean_shape;
  V = model.deformation_shapes;
  sigma_sq = model.sigma_sq;
  K = size(model.deformation_shapes,1)/3;
  [T, J] = size(MD);
  P_hat = P; % if any of the points are missing, P_hat will be updated during the M-step
  [R_init, Trvect] = rigidfac_known_shape(P_hat, MD,S_bar);
  %[R_init, Trvect, S_bar] = rigidfac_known_shape2(P_hat, MD,S_bar);
  Tr(:,1) = Trvect(1:T);
  Tr(:,2) = Trvect(T+1:2*T);

  R = zeros(2*T, 3);
  % enforces rotation constraints
  for t = 1:T,
     Ru = R_init(t,:);
     Rv = R_init(T+t,:);
     Rz = cross(Ru,Rv); if det([Ru;Rv;Rz])<0, Rz = -Rz; end;
     RO_approx = apprRot([Ru;Rv;Rz]);
     RO{t} = RO_approx;
     R(t,:) = RO_approx(1,:);
     R(t+T,:) = RO_approx(2,:);
  end;

  loglik = 0;
  for em_iter=1:max_em_iter,   
    % computes the hidden variables distributions
    [E_z, E_zz] = estep_compute_Z_distr(P_hat, S_bar, V, R, Tr, sigma_sq);     % (Eq 17-18)
    
    Z = E_z';
    % fills in missing points
    if sum(MD(:))>0,
      P_hat = mstep_update_missingdata(P_hat, MD, S_bar, V, E_z, RO, Tr);     % (Eq 25)
    end

    % updates rotation
    [RO, R] = mstep_update_rotation(P_hat, S_bar, V, E_z, E_zz, RO, Tr);       % (Eq 24)
    
    % updates translation
    Tr = mstep_update_transl(P_hat, S_bar, V, E_z, RO);                        % (Eq 23)

    % computes log likelihood
    oldloglik = loglik;
    loglik = compute_log_lik(P_hat, S_bar, V, E_z, E_zz, RO, Tr, sigma_sq);
%     fprintf('LogLik(%d): %f\n', em_iter, loglik);

  end

  P3 = zeros(3*T, J);
  for t = 1:T,
     z_t = Z(t,:);
     Rf = [R(t,:); R(t+T,:)];
     S = S_bar;
     for kk = 1:K,
        S = S+z_t(kk)*V((kk-1)*3+[1:3],:);
     end;
     S = RO{t}*S;

     P3([t t+T t+2*T], :) = S + [Tr(t, [1 2]) -mean(S(3,:))]'*ones(1,J);
  end
