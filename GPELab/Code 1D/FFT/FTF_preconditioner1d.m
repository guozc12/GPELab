%% Applying the full Thomas-Fermi preconditioner
%% INPUTS:
%%          Phi_in: Initial component functions (vector)
%%          Method: Structure containing variables concerning the method (structure) (see Method_Var1d.m)
%%          FFTGeometry1D: Structure containing variables concerning the geometry of the problem in 1D in the FFT context (structure) (see FFTGeometry1D_Var1d.m)
%%          FFTPhysics1D: Structure containing variables concerning the physics of the problem in 1D in the FFT context (structure) (see FFTPhysics1D_Var1d.m)
%% OUTPUT:
%%          Phi_out: Component functions with the operators applied (vector)

function [Phi_out] = FTF_preconditioner1d(Phi_in, Method, FFTGeometry1D, FFTPhysics1D)
%% Initialization of variables
Phi_in = reshape(Phi_in,Method.Ncomponents*FFTGeometry1D.Nx,1); % Reshaping vector as a matrix
Phi_out = Phi_in; % Initializing the variable for the component functions with the preconditioner applied

%% Applying the Thomas-Fermi preconditionner
% FOR each component
for n = 1:Method.Ncomponents
    Phi_tmp{n} = Phi_in((1+(n-1)*FFTGeometry1D.Nx):(n*FFTGeometry1D.Nx)); % Exctraction the wave function of a component
end
% FOR each component
for n = 1:Method.Ncomponents
    Phi = zeros(FFTGeometry1D.Nx,1);
    % FOR each component
    for m = 1:Method.Ncomponents
        Phi = Phi + FFTPhysics1D.FPThomasFermi{n,m}.*Phi_tmp{m}; % Applying the Thomas-Fermi preconditoner
    end
    Phi_out((1+(n-1)*FFTGeometry1D.Nx):(n*FFTGeometry1D.Nx)) = Phi; % Storing the wave function of a component with the Thomas-Fermi preconditoner applied
end

%% Reshapping as a vector the output
Phi_out = reshape(Phi_out,Method.Ncomponents*FFTGeometry1D.Nx,1); % Reshapping the wave functions as a vector