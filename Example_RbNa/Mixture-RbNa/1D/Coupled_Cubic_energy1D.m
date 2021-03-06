function [CoupledCubicEnergy] = Coupled_Cubic_energy1D(Beta)

CoupledCubicEnergy = cell(2);
CoupledCubicEnergy{1,1} = @(Phi,X)(1/2)*Beta(1,1)*abs(Phi{1}).^2+(1/2)*Beta(1,2)*abs(Phi{2}).^2;
CoupledCubicEnergy{2,2} = @(Phi,X)(1/2)*Beta(2,2)*abs(Phi{2}).^2+(1/2)*Beta(2,1)*abs(Phi{1}).^2;
CoupledCubicEnergy{1,2} = @(Phi,X) 0;
CoupledCubicEnergy{2,1} = @(Phi,X) 0;