%% SPLitting scheme for the Dynamic System (SPL-DS) : Semi-implicit FFT scheme for the computation of the dynamic Gross Pitaevskii equation
%% INPUTS:
%%          Phi_0: Initial wave functions (cell array)
%%          Method: Structure containing variables concerning the method (structure) (see Method_Var3d.m)
%%          Geometry3D: Structure containing variables concerning the geometry of the problem in 3D (structure) (see Geometry3D_Var3d.m)
%%          Physics3D: Structure containing variables concerning the physics of the problem in 3D (structure) (see Physics3D_Var3d.m)
%%          Outputs: Different outputs computed during the computation of the problem (structure) (see OutputsINI_Var3D.m and FFTOutputs_Var3d.m)
%%          Print: Structure containing variables concerning the printing and drawing of informations during the computations (structure) (see Print_Var3d.m)
%%          Figure: Structure containing variables concerning the figures (structure)
%% OUTPUTS:
%%          Phi_final: Dynamic's wave functions computated with the BESP method (cell array)
%%          Outputs: Different outputs computed during the computation of the problem (structure) (see OutputsINI_Var3D.m and FFTOutputs_Var3d.m)
%% FUNCTIONS USED:
%%          FFTGeometry3D_Var3d: To compute the 3d geometry used for the FFT (line 30)
%%          FFTPhysics3D_Var3d: To compute the 3d physics used for the FFT (line 31)
%%          FFTOperators3D_Var3d: To compute the 3d operators used for the FFT (line 39)
%%          Local_Full_BESP_solution3d: To compute the CNGF on a single time step using the full BESP method (line 56)
%%          Local_Partial_BESP_solution3d: To compute the CNGF on a single time step using the partial BESP method (line 62)
%%          FFTOutputs_Var3d: To compute output variables (line 74,78 and 91)
%%          Print_Info3d: To print informations concerning the wave functions (line 81 and 92)
%%          Draw_solution3d: To draw the ground states (line 85)

function [Phi_final, Outputs] = SPL_DS3d(Phi_0, Method, Geometry3D, Physics3D, Outputs, Print, Figure)

%% CPUtime initilization
Method.Cputime = 0; % Initialization of the CPUtime variable
Method.Cputime_temp = cputime; % Initialization of the relative CPUtime variable

%% Geometry, operators, physics and ground states initialization for FFT
FFTGeometry3D = FFTGeometry3D_Var3d(Geometry3D); % Changing the geometry for the FFT
FFTOperators3D = FFTOperators3D_Var3d(FFTGeometry3D); % Computing the derivative FFT operators
% Changing the solution for the FFT
% FOR each component
for n = 1:Method.Ncomponents
    FFTPhi{n} = Phi_0{n}(1:FFTGeometry3D.Ny,1:FFTGeometry3D.Nx,1:FFTGeometry3D.Nz); % Removing boundaries for the FFT
end
FFTPhysics3D = FFTPhysics3D_Var3d(FFTPhi, Method, Physics3D, FFTGeometry3D, FFTOperators3D); % Changing the physics for the FFT


%% CPUtime initilization bis 
Method.Cputime_temp = cputime - Method.Cputime_temp; % Storing the CPUtime relatively to the begining of the program
Method.Cputime  = Method.Cputime + Method.Cputime_temp;  % Updating the CPUtime variable

%% Computation of dynamic of the GPE via Splitting
% Stopping criterions: stopping time
while (Method.Iterations*Method.Deltat<Method.Stop_time)
    %% Updating variables
    Method.Cputime_temp = cputime; % Reinitialization of the relative CPUtime variable
    Method.Iterations = Method.Iterations + 1; % Iteration count

    %% Computing ground state using the Splitting method  
    FFTPhi = Local_Splitting_solution3d(FFTPhi, Method, FFTGeometry3D, FFTPhysics3D, FFTOperators3D); % Computation of the ground state using the full BESP-CNFG method on a single step of time

    %% Updating CPUtime
    Method.Cputime_temp = cputime - Method.Cputime_temp; % Storing the CPUtime relatively to the begining of the "while" loop
    Method.Cputime = Method.Cputime + Method.Cputime_temp; % Updating the CPUtime variable
    
    %% Computation of outputs
    % IF one wants to either compute outputs or to print informations during 
    % the computation
    if (Method.Output) && (mod(Method.Iterations,Outputs.Evo_outputs) == 0)
        Outputs = FFTOutputs_Var3d(FFTPhi, Outputs, Method, FFTGeometry3D, FFTPhysics3D, FFTOperators3D); % Computing the output variables
    end
    %% Printing informations and drawing ground states
    % IF the number of iterations has been reached
    if (mod(Method.Iterations,Print.Evo) == 0)
        % IF one has chosen to print informations and the outputs are
        % already computed
        if (Method.Output) && (Print.Print == 1)
            Print_Info3d(Outputs, Method) % Printing informations
        % ELSEIF one has chosen to print informations and the outputs are
        % not computed
        elseif (~Method.Output) && (Print.Print == 1)
            Outputs_tmp = FFTOutputs_Var3d(FFTPhi, Outputs, Method, FFTGeometry3D, FFTPhysics3D, FFTOperators3D);
            Print_Info3d(Outputs_tmp, Method) % Printing informations
        end
        % IF one has chosen to draw the ground states
        if (Print.Draw == 1)
            Draw_solution3d(FFTPhi,Method,FFTGeometry3D,Figure) % Drawing the wave functions' modulus square and angle
        end;
    end
end

%% Printing the informations of the final ground states
Outputs = FFTOutputs_Var3d(FFTPhi, Outputs, Method, FFTGeometry3D, FFTPhysics3D, FFTOperators3D); % Computing the output variables
Print_Info3d(Outputs, Method) % Printing informations

%% Finalization of the ground states
% FOR each component
for n = 1:Method.Ncomponents
Phi_final{n} = zeros(Geometry3D.Ny,Geometry3D.Nx,Geometry3D.Nz); % Initializing the variable for the storing of the final ground states
Phi_final{n}(1:FFTGeometry3D.Ny,1:FFTGeometry3D.Nx,1:FFTGeometry3D.Nz) = FFTPhi{n}; % Storing of the ground states solutions
Phi_final{n}(FFTGeometry3D.Ny+1,1:FFTGeometry3D.Nx,1:FFTGeometry3D.Nz) = FFTPhi{n}(1,:,:); % Setting the boundary of the ground states solutions
Phi_final{n}(1:FFTGeometry3D.Ny,FFTGeometry3D.Nx+1,1:FFTGeometry3D.Nz) = FFTPhi{n}(:,1,:); % Setting the boundary of the ground states solutions
Phi_final{n}(1:FFTGeometry3D.Ny,1:FFTGeometry3D.Nx,FFTGeometry3D.Nz+1) = FFTPhi{n}(:,:,1); % Setting the boundary of the ground states solutions
Phi_final{n}(FFTGeometry3D.Ny+1,FFTGeometry3D.Nx+1,FFTGeometry3D.Nz+1) = FFTPhi{n}(1,1,1); % Setting the boundary of the ground states solutions
end