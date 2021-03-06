%% Computing the Full Laplace preconditioner for the BESP scheme
%% INPUTS:
%%          Method: Structure containing variables concerning the method (structure) (see Method_Var1d.m)
%%          FFTPhysics1D: Structure containing variables concerning the physics of the problem in 1D in the FFT context (structure) (see FFTPhysics1D_Var1d.m)
%%          FFTOperators1D: Structure containing the derivative FFT operators (structure) (see FFTOperators1D_Var1d.m)
%% OUTPUT:
%%          FPLaplace: the full Laplace preconditioner (structure)

function FPLaplace = BESPFPLaplace1d(Method, FFTPhysics1D, FFTGeometry1D)
%% Initialization of the potential and nonlinear matricial operators 
DispMat = cell(Method.Ncomponents);
for n = 1:Method.Ncomponents
    for m = 1:Method.Ncomponents
        DispMat{n,m} = (n == m)*1/Method.Deltat + FFTPhysics1D.Dispersion{n,m};
    end
end
%% Computation of the full ThomasFermi preconditioner
% IF there are more than one component
if (Method.Ncomponents ~= 1)
    LocalFLaplace{1,1} = 1./DispMat{1,1}; % Initialization of the local Laplace preconditioner
    for n = 1:Method.Ncomponents-1
        %% Storing submatrices
        for k = 1:n
            B{k} = DispMat{k,n+1};
            C{k} = DispMat{n+1,k};
        end
        %% Computing intermediary matrices
        E = DispMat{n+1,n+1};
        for k = 1:n
            G{k} = zeros(FFTGeometry1D.Nx,1);
        end
        for k = 1:n
            for l = 1:n
                G{k} = G{k} + C{l}.*LocalFLaplace{l,k};
            end
        end
        for k = 1:n
            E = E - G{k}.*B{k};
        end
        E = 1./E;
        for k = 1:n
            F{k} = zeros(FFTGeometry1D.Nx,1);
        end
        for k = 1:n
            for l = 1:n
                F{k} = F{k} + LocalFLaplace{k,l}.*B{l};
            end
        end
        for k = 1:n
            for l = 1:n
                H{k,l} = E.*F{k}.*G{l};
            end
        end
        %% Computing the intermediary full Laplace preconditioner
        LocalFLaplace{n+1,n+1} = E;
        for k = 1:n
            LocalFLaplace{k,n+1} = -E.*F{k};
            LocalFLaplace{n+1,k} = -E.*G{k};
            for l = 1:n
                LocalFLaplace{k,l} = LocalFLaplace{k,l}+H{k,l};
            end
        end
    end
FPLaplace = LocalFLaplace; % Storing the full Laplace preconditioner
%ELSEIF there is only one component
elseif (Method.Ncomponents == 1)
    FPLaplace{1} = 1./DispMat{1,1}; % Storing the full Laplace preconditioner
end
        