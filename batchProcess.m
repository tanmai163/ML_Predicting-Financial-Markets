% Batch Processing
% Coventry University - Individual Project
% 03/01/2021
% Paul Johannes Aru



% +++ CONFIGURATION +++
classSize   = [3];        % Up/Down or High-Up/Up/Low-Up/No-Change/...
windowSize  = [14];       % Number of Previous Days in a Data Point
shareList   = {{'BTC-USD','BTC-EUR'},{'BTC-USD','GC=F'},{'BTC-USD','^GSPC'}}; % Market Symbols to Track
hiddenUnits = [1500];     % LSTM Memory Element (i.e. How Much the Model Remembers)
epochLimit  = [5000];      % Number of Loops Through Data Set
extendLog   = false;      % Include Log from Sub-Scripts (For Debugging)
batchSize   = [1500]; % Number of Data Points Proccessed in a Batch
startDate   = [(datetime('today')-(calyears(5)+caldays(1)))]; % 

fileTime = datetime('now');fileTime.Format = 'dd.MM.yyyy-HH.mm';
logFile = fopen(append('Log_',string(fileTime),'.txt'), 'w');
for i=1:length(windowSize)
    for ii=1:length(classSize)
        for iii=1:length(shareList)
            for iiii=1:length(hiddenUnits)
                for iiiii=1:length(epochLimit)
                    for iiiiii=1:length(batchSize)
                        for iiiiiii=1:length(startDate)
                            testTime = datetime('now');testTime.Format = 'dd/MM/yyyy HH:mm';
                            dataTime = startDate(iiiiiii);dataTime.Format = 'dd/MM/yyyy';
                            testShares='';
                            for j=1:length(shareList{iii})
                                testShares=append(testShares,shareList{iii}{j},', ');
                            end
                            fprintf('\nStarting Test %i at %s\n',(i*ii*iii*iiii*iiiii*iiiiii*iiiiiii),string(testTime))
                            fprintf('[Window-Size %i, %i Class(es), %i Symbol(s), %i Hidden-Unit(s), Epoch-Limit %i & Batch-Size %i]\n',windowSize(i),classSize(ii),length(shareList{iii}),hiddenUnits(iiii),epochLimit(iiiii),batchSize(iiiiii))
                            fprintf('[Start: %s - %s]\n',string(dataTime),testShares)
                            fprintf(logFile, '\nStarting Test %i at %s \n',(i*ii*iii*iiii*iiiii*iiiiii*iiiiiii),string(testTime));
                            fprintf(logFile, '[Window-Size %i, %i Class(es), %i Symbol(s), %i Hidden-Unit(s), Epoch-Limit %i & Batch-Size %i]\n',windowSize(i),classSize(ii),length(shareList{iii}),hiddenUnits(iiii),epochLimit(iiiii),batchSize(iiiiii));
                            fprintf(logFile, '[Start: %s - %s]\n',string(dataTime),testShares);
                            
                            datasetInfo = downloadSequencedTrainingData(windowSize(i),classSize(ii),extendLog,shareList{iii},startDate(iiiiiii));
                            fprintf('Dataset Finished! Created: %i datapoints.\n',sum(str2double(datasetInfo(2,:))))
                            fprintf(logFile,'Dataset Finished! Created: %i datapoints.\n',sum(str2double(datasetInfo(2,:))));
                
                            [model,oldAccuracy,newAccuracy] = createLSTM(extendLog,hiddenUnits(iiii),epochLimit(iiiii),batchSize(iiiiii));
                            fprintf('Training Finished!\nThis Model is %.2f%% Precisely Accurate\n', (oldAccuracy))
                            fprintf(logFile, 'Training Finished!\nThis Model is %.2f%% Precisely Accurate\n', (oldAccuracy));
                            fprintf('          and %.2f%% Directionally Accurate.\n',(newAccuracy))
                            fprintf(logFile, '          and %.2f%% Directionally Accurate.\n',(newAccuracy));
                
                            [simulationEarnings,simulationPredictions]=calculateEarnings(model,windowSize(i),extendLog,shareList{iii},batchSize(iiiiii));
                            fprintf('Simulating Finished!\nThis Model earned %.2f$.\n', (simulationEarnings))
                            fprintf(logFile, 'Simulating Finished!\nThis Model earned %.2f$.\n', (simulationEarnings));
                        end
                    end
                end
            end
        end
    end
end
fclose('all');