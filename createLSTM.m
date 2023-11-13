% Train a LSTM Neural Network
% Coventry University - Individual Project
% 29/12/2020
% Paul Johannes Aru



function [model,accuracy,dirAccuracy] = createLSTM(log,numHiddenUnits,maxEpochs, miniBatchSize)

% Settings:
directory = '../../Dataset';
%log = true;



% --- IMPORT DATASET ---
if log
    disp('IMPORTING...')
end
% Import Dataset from .csv files
dataSet = cell2table(cell(0,2)); dataSet.Properties.VariableNames={'Input','Output'};
cd(directory);
classNames=dir;classNames=classNames([classNames.isdir]);classNames={classNames.name};classNames=classNames(3:end);
% Loop Through Each Class (Directory)
for class=1:length(classNames)
    cd(string(classNames(class)));
    fileNames=dir;fileNames=fileNames(~[fileNames.isdir]); fileNames={fileNames.name};
    
    % Loop Through Each Data Point (.csv File)
    for file=1:length(fileNames)
        if contains(string(fileNames(file)),'.csv')
            data = readtable(string(fileNames(file)),'TextType','String');
            data.Properties.RowNames=table2array(data(:,1));data=data(:,2:end);
            data=data{:,:};
            dataSet=[dataSet;cell2table({data, string(classNames(class))},'VariableNames',{'Input','Output'})];
        end
    end
    cd '../';
end
cd '../';
sampleSize = length(dataSet{:,1});
if log
    fprintf('%d Data Points Imported\n', sampleSize)
end



% --- FORMAT DATASET ---
if log
    disp('FORMATING...')
end
dataSet = convertvars(dataSet,"Output",'categorical');
% Split & Randomise the Data for Training and Testing
trainSampleSize = floor(0.9*sampleSize);
testSampleSize = sampleSize - trainSampleSize;
sampleOrder = randperm(sampleSize);
trainSampleOrder = sampleOrder(1:trainSampleSize);
testSampleOrder = sampleOrder(trainSampleSize+1:end);
trainData = dataSet(trainSampleOrder,:);
testData = dataSet(testSampleOrder,:);
% Split Input & Output for LSTM
inputData=trainData{:,1};
outputData=trainData{:,2};



% --- TRAIN NEURAL NETWORK ---
if log
    disp('TRAINING...')
end
inputSize = length(data(:,1));
%numHiddenUnits = 1000;
numClasses = numel(classNames);

layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

%maxEpochs = 5000;
%miniBatchSize = 1500;
options = trainingOptions('adam', ...
    'ExecutionEnvironment','auto', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'Verbose',false, ...
    'Plots','training-progress');

model = trainNetwork(inputData,outputData,layers,options);



% --- TEST MODEL ---
if log
    disp('TESTING...')
end
% Split Input & Output for LSTM
inputTestData=testData{:,1};
outputTestData=testData{:,2};
% Calcualte Accuracy
testPrediction = classify(model,inputTestData,'MiniBatchSize',miniBatchSize);
accuracy = sum(testPrediction == outputTestData)./numel(outputTestData);
statArray=(contains(string(testPrediction(1)),"Up")&contains(string(outputTestData(1)),"Up")|contains(string(testPrediction(1)),"Down")&contains(string(outputTestData(1)),"Down"));
for i=2:length(testPrediction)
    statArray=[statArray, (contains(string(testPrediction(i)),"Up")&contains(string(outputTestData(i)),"Up") | contains(string(testPrediction(i)),"Down")&contains(string(outputTestData(i)),"Down") | contains(string(testPrediction(i)),"No_Change")&contains(string(outputTestData(i)),"No_Change"))];
end
dirAccuracy = sum(statArray)./numel(outputTestData);
accuracy = accuracy*double(100); dirAccuracy = dirAccuracy*double(100);

if log
    fprintf('Finished!\nThis Model is %.2f%% Precisely Accurate\n', (accuracy))
    fprintf('and %.2f%% Directionally Accurate.\n',(dirAccuracy))
end
%cd 'MATLAB Drive/Testing Area'; %Windows
cd 'MATLAB-Drive/Testing Area'; %macOS

end