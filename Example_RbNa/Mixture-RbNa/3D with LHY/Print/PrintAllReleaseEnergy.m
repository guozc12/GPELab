clear;
matPath = 'C:\Users\Zhichao Guo\Documents\GitHub\GPELab\Example_RbNa\Mixture-RbNa\3D with LHY\playground\onlyMF\';
matDIR = dir([matPath '*.mat']);
l = length(matDIR);

a12 = zeros(l,1);
Energy_release = zeros(l,1);

for i = 1:l
    tempdata = load([matPath matDIR(i).name]);
    a12(i) = tempdata.data.Constants.a12/tempdata.data.Constants.a0;
    Energy_release(i) = (1/(tempdata.data.Number.Na + tempdata.data.Number.Rb))* ...
        (( tempdata.data.Outputs.Dispersion_energy{1}(end) + ...
           0.5*tempdata.data.Outputs.Nonlinear_energy{1}(end) ...
        ) * tempdata.data.Number.Na + ...
        ( tempdata.data.Outputs.Dispersion_energy{2}(end) + ...
           0.5*tempdata.data.Outputs.Nonlinear_energy{2}(end) ...
        ) * tempdata.data.Number.Rb);
end

[a12_sorted, a12_order] = sort(a12);
Energy_release = Energy_release(a12_order);

figure
plot(a12_sorted, Energy_release);