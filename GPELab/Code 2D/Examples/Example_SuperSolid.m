%%% This file is an example of how to use GPELab (FFT version)

%% GROUND STATE COMPUTATION WITH A ROTATING TERM


%-----------------------------------------------------------
% Setting the data
%-----------------------------------------------------------

%% Setting the method and geometry
Computation = 'Ground';
Ncomponents = 1;
Type = 'BESP';
Deltat = 1e-3;
Stop_time = [];
Stop_crit = {'Energy',1e-6};
Method = Method_Var2d(Computation, Ncomponents, Type, Deltat, Stop_time, Stop_crit);
xmin = -15;
xmax = 15;
ymin = -15;
ymax = 15;
Nx = 2^8+1;
Ny = 2^8+1;
Geometry2D = Geometry2D_Var2d(xmin,xmax,ymin,ymax,Nx,Ny);

%% Setting the physical problem
Delta = 0.5;
Beta = 3000;
gamma = 5;
BetaDipole = 10;
R0 = 1.5;
Physics2D = Physics2D_Var2d(Method, Delta, Beta);
Physics2D = Dispersion_Var2d(Method, Physics2D);
Physics2D = Potential_Var2d(Method, Physics2D, @(X,Y) gamma^2/2*(X.^2+Y.^2));
Physics2D = Nonlinearity_Var2d(Method, Physics2D);
Physics2D = FFTNonlinearity_Var2d(Method, Physics2D, @(Phi,X,Y,FFTX,FFTY) BetaDipole*RydBergInteraction2d(R0,Phi,FFTX,FFTY),...
[],@(Phi,X,Y,FFTX,FFTY) BetaDipole*RydBergInteraction_energy2d(R0,Phi,FFTX,FFTY));


%% Setting the initial data
InitialData_Choice = 1;
Phi_0 = InitialData_Var2d(Method, Geometry2D, Physics2D, InitialData_Choice);

%% Setting informations and outputs
Outputs = OutputsINI_Var2d(Method);
Printing = 1;
Evo = 15;
Draw = 1;
Print = Print_Var2d(Printing,Evo,Draw);

%-----------------------------------------------------------
% Launching simulation
%-----------------------------------------------------------

[Phi, Outputs] = GPELab2d(Phi_0,Method,Geometry2D,Physics2D,Outputs,[],Print);