%% test release energy
clear;
%Blist = [350.45077,350.21925,350.12664,350.03403,349.98773,349.94143,349.91827,349.89512];
chi = -30:5:100;
NNalist = [84402.16925,72813.8197,61495.42154,50711.76394,49311.90757, ...
           36651.72256,28474.50752,18698.37643];
NRblist = 1.43*NNalist;
halfsize = [10,10,10,10,10,10,10,10];


%a12list = -75.2:1:-64.2; % total 16 points
%NNalist = 10.^(5.2:0.3:5.2); % total 8 points
%NRblist = NNalist*1.43;
%halfsize = 5.25:0.75:13.5;

for j = 1:length(NNalist)  % loop of number
        a12list = (chi/3.5-60)/84402*NNalist(j);
        a12bar = a12list(1);
        NNa = NNalist(j);
        NRb = NRblist(j);   
        gNa = 0;gRb = 0;
        CharaLength = 1.6E-6;
        LHY_Q = 1;
        data_0 = SetData0(NRb, NNa, a12bar, gNa, gRb, LHY_Q, CharaLength, halfsize(1));
        data = RunGPE(data_0);
        save([num2str(LHY_Q) 'LHYQ' '-NNa' num2str(NNa) '-NRb' num2str(NRb) '-a12' num2str(a12bar)  '.mat'],'data');
    
    for i = 2:length(a12list)  % loop of a12
        a12bar = a12list(i);
        data_0 = SetData0(NRb, NNa, a12bar, gNa, gRb, LHY_Q, CharaLength, halfsize(i));
        data_0.Phi = data.Phi;
        data = RunGPE(data_0);
        save([num2str(LHY_Q) 'LHYQ-droplet' '-NNa' num2str(NNa) '-NRb' num2str(NRb) '-a12' num2str(a12bar)  '.mat'],'data');
    end
end