%% Computing the Full ThomasFermi preconditioner for the BESP scheme
%% INPUTS:
%%          Method: Structure containing variables concerning the method (structure) (see Method_Var1d.m)
%%          FFTPhysics2D: Structure containing variables concerning the physics of the problem in 1D in the FFT context (structure) (see FFTPhysics1D_Var1d.m)
%% OUTPUT:
%%          FPTHomasFermi: the full ThomasFermi preconditioner (structure)

function FPTHomasFermi = BESPFPThomas_Fermi1d(Method, FFTPhysics1D, FFTGeometry1D)
%% Initialization of the potential and nonlinear matricial operators 
PotNLMat = cell(Method.Ncomponents);
for n = 1:Method.Ncomponents
    for m = 1:Method.Ncomponents
        PotNLMat{n,m} = (n == m)*1/Method.Deltat + FFTPhysics1D.Potential{n,m} + FFTPhysics1D.TimePotential{n,m}+ FFTPhysics1D.Beta*FFTPhysics1D.Nonlinearity{n,m} + FFTPhysics1D.Beta*FFTPhysics1D.FFTNonlinearity{n,m};
    end
end
%% Computation of the full ThomasFermi preconditioner
% IF there are more than one component
if (Method.Ncomponents ~= 1)
    LocalFThomasFermi{1,1} = 1./PotNLMat{1,1}; % Initialization of the local full ThomasFermi preconditioner
    for n = 1:Method.Ncomponents-1
        %% Storing submatrices
        for k = 1:n
            B{k} = PotNLMat{k,n+1};
            C{k} = PotNLMat{n+1,k};
        end
        %% Computing intermediary matrices
        E = PotNLMat{n+1,n+1};
        for k = 1:n
            G{k} = zeros(FFTGeometry1D.Nx,1);
        end
        for k = 1:n
            for l = 1:n
                G{k} = G{k} + C{l}.*LocalFThomasFermi{l,k};
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
                F{k} = F{k} + LocalFThomasFermi{k,l}.*B{l};
            end
        end
        for k = 1:n
            for l = 1:n
                H{k,l} = E.*F{k}.*G{l};
            end
        end
        %% Computing the intermediary full Thomas Fermi preconditioner
        LocalFThomasFermi{n+1,n+1} = E;
        for k = 1:n
            LocalFThomasFermi{k,n+1} = -E.*F{k};
            LocalFThomasFermi{n+1,k} = -E.*G{k};
            for l = 1:n
                LocalFThomasFermi{k,l} = LocalFThomasFermi{k,l}+H{k,l};
            end
        end
    end
FPTHomasFermi = LocalFThomasFermi; % Storing the full Thomas Fermi preconditioner
%ELSEIF there is only one component
elseif (Method.Ncomponents == 1)
    FPTHomasFermi{1} = 1./PotNLMat{1,1}; % Storing the full Thomas Fermi preconditioner
end