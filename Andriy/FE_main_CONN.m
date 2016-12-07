addpath('./code/') ;
mydir = {'train_1','train_2','train_3','test_1','test_2','test_3','test_1_new','test_2_new','test_3_new'};
srateNew = 256;
windL = 30; % window length in s
windS = 30; % window shift in s

for i1 = 1: size(mydir,2)
    names = dir(['../data/' mydir{i1}]);
    for i2=3:size(names,1)
        fprintf('\n%d-%d',i1,i2-2);
        load(['../data/' mydir{i1} '/' names(i2).name]);
        dataStruct.data = dataStruct.data';
        %load(['../feat/' mydir{i1} '/' names(i2).name(1:end-4) '_feat']);
        % Highpass Filter coefficient
        Fchp = 0.5;
        alpha = (2*pi*Fchp)/double(dataStruct.iEEGsamplingRate);
        
        % 60Hz notch filter
        fs = double(dataStruct.iEEGsamplingRate);               %#sampling rate
        f0 = 60;                %#notch frequency
        fn = fs/2;              %#Nyquist frequency
        freqRatio = f0/fn;      %#ratio of notch freq. to Nyquist freq.
        notchWidth = 0.05;       %#width of the notch
        %Compute zeros
        myzeros = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];
        %Compute poles
        mypoles = (1-notchWidth) * myzeros;
        b = poly( myzeros ); %# Get moving average filter coefficients
        a = poly( mypoles ); %# Get autoregressive filter coefficients
        
        
        
        for ii=1:size(dataStruct.data,1)
            dataStruct.data(ii,:) = dataStruct.data(ii,:) - mean(dataStruct.data(ii,:)); % centering
            LPOutput = filter(b,a,dataStruct.data(ii,:));
            HPOutput = zeros(size(LPOutput));
            HPOutput(1) = LPOutput(1);
            for iIndex = 2:length(LPOutput)
                HPOutput(iIndex) = (1 - alpha)*HPOutput(iIndex-1) + LPOutput(iIndex) - LPOutput(iIndex-1);
            end
            dataStruct.data(ii,:) = HPOutput;
        end
        dataStruct.data = double(dataStruct.data(:,dataStruct.iEEGsamplingRate*4:end-dataStruct.iEEGsamplingRate*4)); % removing 4 first and last seconds due to filtering
        dataStruct.data = (resample(dataStruct.data',srateNew,double(dataStruct.iEEGsamplingRate)))';
        featCon = NaN(fix(((length(dataStruct.data(1,:)))-windL*srateNew+windS*srateNew)/(windS*srateNew)),180);
        dataCh = enframe(dataStruct.data(1,:),windL*srateNew,windS*srateNew);
        feat_params_st.PSD_window=1; % seconds was4
        feat_params_st.PSD_overlap=0; % seconds was3 %
        
        fprintf('.');
        for iii=1:size(dataCh,1)
            datatmp = dataStruct.data(:,(iii-1)*srateNew*windS+1:srateNew*((iii-1)*windS+windL));
            if all(all(datatmp==0))
                continue;
            end
            featCon(iii,1:180) = connectivity_features_ALL(datatmp,srateNew,[0.5 4; 3 8; 7 15; 14 31; 30 100],1,0);
        end
        
        if exist(['./feat/' mydir{i1} '/']) ~= 7
            mkdir(['./feat/' mydir{i1} '/']);
        end
        
        save(['./feat/' mydir{i1} '/' names(i2).name(1:end-4) '_connFull'],'featCon');
    end
end
