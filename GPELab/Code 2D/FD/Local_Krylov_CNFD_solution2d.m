%% Computation of a step in time using an iterative Krylov method with CNFD scheme
%% INPUTS:
%%          Phi: Initial wave functions in the 2D geometry for the FD (cell array)
%%          Method: Structure containing variables concerning the method (structure) (see Method_Var2d.m)
%%          FDGeometry2D: Structure containing variables concerning the geometry of the problem in 2D in the FD context (structure) (see FDGeometry2D_Var2d.m)
%%          FDPhysics2D: Structure containing variables concerning the physics of the problem in 2D in the FD context (structure) (see FDPhysics2D_Var2d.m)
%%          FDOperators2D: Structure containing the derivative FFT operators (structure) (see FDOperators2D_Var2d.m)
%% OUTPUTS:
%%          Phi: Wave functions computated with the BEFD method on a single step (cell array)
%%          [flag,relres,iter,resvec]: Outputs from bicgstab (vector) (see bicgstab.m)
%% FUNCTIONS USED:
%%          bicgstab: To compute the wave functions by an iterative method (line 59)

function [Phi, flag, relres, iter, resvec] = Local_Krylov_CNFD_solution2d(Phi, Method, FDGeometry2D, FDPhysics2D, FDOperators2D)

%% Computing the explicit nonlinearity and the time-dependent potential
% FOR each component
for n = 1:Method.Ncomponents
    % FOR each component
    for m = 1:Method.Ncomponents
        Nonlinearity_tmp = FDPhysics2D.Nonlinearity_function{n,m}(Phi,FDGeometry2D.X,FDGeometry2D.Y); % Computing the nonlinearity
        % IF the nonlinearity is a scalar
        if (isscalar(Nonlinearity_tmp))
            NL_scal = Nonlinearity_tmp; % Storing the scalar value of the nonlinearity
            Nonlinearity_tmp = NL_scal*ones(FDGeometry2D.Ny,FDGeometry2D.Nx); % Reconstructing for the nonlinearity
        end
        % IF this is the coupled nonlinearity with the first component
        if (m == 1)
            Nonlinearity_matrix_tmp = spdiags(reshape(Nonlinearity_tmp,FDGeometry2D.N2,1),0,FDGeometry2D.N2,FDGeometry2D.N2); % Initialiazing the temporary local nonlinearity matrix
        % ELSE if this is the coupled nonlinearity with other components
        else
            Nonlinearity_matrix_tmp = horzcat(Nonlinearity_matrix_tmp, spdiags(reshape(Nonlinearity_tmp,FDGeometry2D.N2,1),0,FDGeometry2D.N2,FDGeometry2D.N2)); % Assembling the local nonlinearity matrix for the 'n' component in the 2D geometry for the FD
        end
    end
    % IF this is the first component
    if (n == 1)
        FDOperators2D.Nonlinearity_matrix = Nonlinearity_matrix_tmp;
    % ELSE if this is not the first component
    else
        FDOperators2D.Nonlinearity_matrix = vertcat(FDOperators2D.Nonlinearity_matrix,Nonlinearity_matrix_tmp); % Adding the part of the local nonlinearity matrix corresponding to the 'n' component to the global matrix
    end
    % FOR each component
    for m = 1:Method.Ncomponents
        TimePotential_tmp = FDPhysics2D.TimePotential_function{n,m}(Method.Iterations*Method.Deltat,FDGeometry2D.X,FDGeometry2D.Y); % Computing the time-dependent potential
        % IF the time-dependent potential is a scalar
        if (isscalar(TimePotential_tmp))
            TP_scal = TimePotential_tmp; % Storing the scalar value of the time-dependent potential
            TimePotential_tmp = TP_scal*ones(FDGeometry2D.Ny,FDGeometry2D.Nx); % Reconstructing for the time-dependent potential
        end
        % IF this is the coupled time-dependent potential with the first component
        if (m == 1)
            TimePotential_matrix_tmp = spdiags(reshape(TimePotential_tmp,FDGeometry2D.N2,1),0,FDGeometry2D.N2,FDGeometry2D.N2); % Initialiazing the temporary local time-dependent potential matrix
        % ELSE if this is the coupled time-dependent potential with other components
        else
            TimePotential_matrix_tmp = horzcat(TimePotential_matrix_tmp, spdiags(reshape(TimePotential_tmp,FDGeometry2D.N2,1),0,FDGeometry2D.N2,FDGeometry2D.N2)); % Assembling the local time-dependent potential matrix for the 'n' component in the 2D geometry for the FD
        end
    end
    % IF this is the first component
    if (n == 1)
        FDOperators2D.TimePotential_matrix = TimePotential_matrix_tmp;
    % ELSE if this is not the first component
    else
        FDOperators2D.TimePotential_matrix = vertcat(FDOperators2D.TimePotential_matrix,TimePotential_matrix_tmp); % Adding the part of the local time-dependent potential matrix corresponding to the 'n' component to the global matrix
    end
end

%% Reshaping the ground states variables as a single vector for the iterative method
Phi_vect = zeros(Method.Ncomponents*FDGeometry2D.N2,1); % Initializing the vector to store each component's wave function
% FOR each component
for n = 1:Method.Ncomponents
    Phi_vect((1+(n-1)*FDGeometry2D.N2):(n*FDGeometry2D.N2)) = reshape(Phi{n},FDGeometry2D.N2,1); % Storing the component's wave function in the vector
end

%% Computing the wave functions after a single time step using Krylov iterative method for CNFD
%If the computation is dynamic
if (strcmp(Method.Computation,'Dynamic'))
    Method.Deltat = 1i*Method.Deltat;
end
% IF one has chosen to use the Laplace preconditioner
if (strcmp(Method.Precond,'Laplace') == 1)
    % Using the iterative method which calls the operator for the implicit 
    % part of the CNFD scheme and the explicit part. Moreover, it uses the 
    % initial components' wave functions as initial vector.
    [Phi_out, flag, relres, iter, resvec] = bicgstab(((1/Method.Deltat)*FDOperators2D.Id + FDOperators2D.Linear_Operators/2 + FDPhysics2D.Beta*FDOperators2D.Nonlinearity_matrix/2 + FDOperators2D.TimePotential_matrix/2),...
    ((1/Method.Deltat)*FDOperators2D.Id - FDOperators2D.Linear_Operators/2 - FDPhysics2D.Beta*FDOperators2D.Nonlinearity_matrix/2 - FDOperators2D.TimePotential_matrix/2)*Phi_vect, Method.Iterative_tol, Method.Iterative_maxit,[],[],Phi_vect);
% ELSEIF one has chosen to use the ThomasFermi preconditioner
elseif (strcmp(Method.Precond,'ThomasFermi') == 1)
   % Using the iterative method which calls the operator with the 
   % Thomas-Fermi preconditioner for the implicit part of the BESP scheme 
   % and the explicit part with the Thomas-Fermi preconditioner applied. 
   % Moreover, it uses the initial components' wave functions as initial vector.
   PThomasFermi_matrix = inv((1/Method.Deltat)*FDOperators2D.Id + FDOperators2D.Potential_matrix/2 + FDOperators2D.TimePotential_matrix/2 + FDPhysics2D.Beta*FDOperators2D.Nonlinearity_matrix/2);
   [Phi_out, flag, relres, iter, resvec] = bicgstab((FDOperators2D.Id + PThomasFermi_matrix*(-FDPhysics2D.Delta*FDOperators2D.Laplacian/2 + FDOperators2D.Gradientx_matrix/2 + FDOperators2D.Gradienty_matrix/2)),...
   PThomasFermi_matrix*((1/Method.Deltat)*FDOperators2D.Id - FDOperators2D.Linear_Operators/2 - FDPhysics2D.Beta*FDOperators2D.Nonlinearity_matrix/2 - FDOperators2D.TimePotential_matrix/2)*Phi_vect, Method.Iterative_tol, Method.Iterative_maxit,[],[],Phi_vect);
% ELSEIF one has chosen not to use any preconditioner
elseif (strcmp(Method.Precond,'None') == 1)
    % Using the iterative method which calls the operator for the implicit 
    % part of the CNFD scheme and the explicit part. Moreover, it uses the 
    % initial components' wave functions as initial vector.
    [Phi_out, flag, relres, iter, resvec] = bicgstab(((1/Method.Deltat)*FDOperators2D.Id + FDOperators2D.Linear_Operators/2 + FDPhysics2D.Beta*FDOperators2D.Nonlinearity_matrix/2 + FDOperators2D.TimePotential_matrix/2),...
    ((1/Method.Deltat)*FDOperators2D.Id - FDOperators2D.Linear_Operators/2 - FDPhysics2D.Beta*FDOperators2D.Nonlinearity_matrix/2 - FDOperators2D.TimePotential_matrix/2)*Phi_vect, Method.Iterative_tol, Method.Iterative_maxit,[],[],Phi_vect);
end
%% Reshaping vector output from the iterative method as matrix
% FOR each component
for n = 1:Method.Ncomponents
    Phi{n} = reshape(Phi_out((1+(n-1)*FDGeometry2D.N2):(n*FDGeometry2D.N2)),FDGeometry2D.Ny,FDGeometry2D.Nx); % Storing the components' wave functions back in a cell array
end