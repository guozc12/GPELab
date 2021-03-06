%% Applying the operators corresponding to the implicit part of the RSP scheme with the Thomas-Fermi preconditioner
%% INPUTS:
%%          Phi_in: Initial components' wave functions (vector)
%%          Psi: Relaxation variable corresponding to the nonlinearity (cell array)
%%          FFTPsi: Relaxation variable corresponding to the non local nonlinearity (cell array)
%%          Method: Structure containing variables concerning the method (structure) (see Method_Var3d.m)
%%          FFTGeometry3D: Structure containing variables concerning the geometry of the problem in 3D in the FFT context (structure) (see FFTGeometry3D_Var3d.m)
%%          FFTPhysics3D: Structure containing variables concerning the physics of the problem in 3D in the FFT context (structure) (see FFTPhysics3D_Var3d.m)
%%          FFTOperators3D: Structure containing the derivative FFT operators (structure) (see FFTOperators3D_Var3d.m)
%% OUTPUT:
%%          Phi_out: Components' wave functions with the operators applied (vector)

function [Phi_out] = operator_Full_RSP_PThomasFermi3d(Phi_in, Psi, FFTPsi, Method, FFTGeometry3D, FFTPhysics3D, FFTOperators3D)
%% Initialization of variables
Phi = cell(1,Method.Ncomponents); % Initializing the variable for the components' wave functions
Gradx_Phi = cell(1,Method.Ncomponents); % Initializing the variable for the gradient of the components' wave functions in the x direction
Grady_Phi = cell(1,Method.Ncomponents); % Initializing the variable for the gradient of the components' wave functions in the y direction
Gradz_Phi = cell(1,Method.Ncomponents); % Initializing the variable for the gradient of the components' wave functions in the z direction
Phi_out = zeros(FFTGeometry3D.Ny,FFTGeometry3D.Nx,Method.Ncomponents*FFTGeometry3D.Nz); % Initializing the variable for the components' wave functions with the operators and the preconditioner applied

%% Computing gradients
% FOR each component
for n = 1:Method.Ncomponents
    Phi{n} = reshape(Phi_in((1+(n-1)*FFTGeometry3D.N3):(n*FFTGeometry3D.N3)),FFTGeometry3D.Ny,FFTGeometry3D.Nx,FFTGeometry3D.Nz); % Storing the components' wave functions back in a cell array
    % IF there are gradient in the y direction functions for this
    % component to compute
    if (FFTPhysics3D.Gradienty_compute_Index{n})
        Grady_Phi{n} = ifft(FFTOperators3D.Gy.*fft(Phi{n},[],1),[],1); % First order derivating the component's wave function on the y direction via FFT and iFFT
    end
    % IF there are gradient in the x direction functions for this
    % component to compute
    if (FFTPhysics3D.Gradientx_compute_Index{n})
        Gradx_Phi{n} = ifft(FFTOperators3D.Gx.*fft(Phi{n},[],2),[],2); % First order derivating the component's wave function on the x direction via FFT and iFFT
    end
    % IF there are gradient in the z direction functions for this
    % component to compute
    if (FFTPhysics3D.Gradientz_compute_Index{n})
        Gradz_Phi{n} = ifft(FFTOperators3D.Gz.*fft(Phi{n},[],3),[],3); % First order derivating the component's wave function on the z direction via FFT and iFFT
    end
end

%% Applying the operators
% FOR each component
for n = 1:Method.Ncomponents
    GPE_Phi = zeros(FFTGeometry3D.Ny,FFTGeometry3D.Nx,FFTGeometry3D.Nz); % Initializing the variable that will contain the wave function with the operators applied
    % FOR each component where the gradient in the x direction is non null
    for m = FFTPhysics3D.Gradientx_function_Index{n}
        GPE_Phi = GPE_Phi + FFTPhysics3D.Gradientx{n,m}.*Gradx_Phi{m}/2; % Computing the wave function with the gradient operators in the x direction applied
    end
    % FOR each component where the gradient in the y direction is non null
    for m = FFTPhysics3D.Gradienty_function_Index{n}
        GPE_Phi = GPE_Phi + FFTPhysics3D.Gradienty{n,m}.*Grady_Phi{m}/2; % Computing the wave function with the gradient operators in the y direction applied
    end
    % FOR each component where the gradient in the z direction is non null
    for m = FFTPhysics3D.Gradientz_function_Index{n}
        GPE_Phi = GPE_Phi + FFTPhysics3D.Gradientz{n,m}.*Gradz_Phi{m}/2; % Computing the wave function with the gradient operators in the z direction applied
    end
    % FOR each component where the potential is non null
    for m = FFTPhysics3D.Potential_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
        GPE_Phi = GPE_Phi + FFTPhysics3D.Potential{n,m}.*Phi{m}/2; % Computing the wave function with the potential operator applied
        end
    end
    % FOR each component where the nonlinearity is non null
    for m = FFTPhysics3D.Nonlinearity_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
        GPE_Phi = GPE_Phi + FFTPhysics3D.Beta*Psi{n,m}.*Phi{m}/2; % Computing the wave function with the nonlinearity operator applied
        end
    end
    % FOR each component where the nonlinearity is non null
    for m = FFTPhysics3D.FFTNonlinearity_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
        GPE_Phi = GPE_Phi + FFTPhysics3D.Beta*FFTPsi{n,m}.*Phi{m}/2; % Computing the wave function with the nonlinearity operator applied
        end
    end
    % FOR each component where the time-dependent potential is non null
    for m = FFTPhysics3D.TimePotential_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
        GPE_Phi = GPE_Phi + FFTPhysics3D.TimePotentialImp{n,m}.*Phi{m}/2; % Computing the wave function with the time-dependent potential operator applied
        end
    end
    % FOR each component where the stochastic potential is non null
    for m = FFTPhysics3D.StochasticPotential_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
        GPE_Phi = GPE_Phi + FFTPhysics3D.StochasticPotential{n,m}.*Phi{m}/2; % Computing the wave function with the time-dependent potential operator applied
        end
    end
    % FOR each component where the dispersion is non null
    for m = FFTPhysics3D.Dispersion_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
            GPE_Phi = GPE_Phi + ifftn(FFTPhysics3D.Dispersion{n,m}.*fftn(Phi{m}))/2; % Computing the wave function with the dispersion operator applied
        end 
    end
    % FOR each component where the dispersion is non null
    for m = FFTPhysics3D.TimeDispersion_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
            GPE_Phi = GPE_Phi + ifftn(FFTPhysics3D.TimeDispersionImp{n,m}.*fftn(Phi{m}))/2; % Computing the wave function with the dispersion operator applied
        end 
    end
    % FOR each component where the stochastic dispersion is non null
    for m = FFTPhysics3D.StochasticDispersion_function_Index{n}
        % IF it is an extradiagonal term
        if (m ~= n)
            GPE_Phi = GPE_Phi + ifftn(FFTPhysics3D.StochasticDispersion{n,m}.*fftn(Phi{m}))/2; % Computing the wave function with the stochastic dispersion applied
        end
    end
    GPE_Phi = GPE_Phi + ifftn((FFTPhysics3D.Dispersion{n,n}/2 + FFTPhysics3D.TimeDispersionImp{n,n}/2 + FFTPhysics3D.StochasticDispersion{n,n}/2).*fftn(Phi{n})); % Computing the wave function with the Laplacian operator applied
    GPE_Phi = Phi{n} + 1./(1/Method.Deltat + FFTPhysics3D.Potential{n,n}/2 + FFTPhysics3D.TimePotentialImp{n,n}/2 + FFTPhysics3D.StochasticPotential{n,n}/2 + FFTPhysics3D.Beta*Psi{n,n}/2 + FFTPhysics3D.Beta*FFTPsi{n,n}/2).*GPE_Phi; % Applying the Thomas-Fermi preconditioner
    Phi_out(:,:,(1+(n-1)*FFTGeometry3D.Nz):(n*FFTGeometry3D.Nz)) = GPE_Phi; % Storing the wave function with the operators and the preconditioner applied
end

%% Reshapping as a vector the output
Phi_out = reshape(Phi_out,Method.Ncomponents*FFTGeometry3D.N3,1); % Reshapping the wave functions as a vector