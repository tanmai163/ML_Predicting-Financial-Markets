% Sequential Market Data Downloader
% Coventry University - Individual Project
% 28/12/2020
% Paul Johannes Aru


%downloadSequencedTrainingDatat(5,3,true,{'EUR=X','CAD=X'}, (datetime('today')-(calyears(19)+caldays(1))))

function classes = downloadSequencedTrainingData(windowSize,numberOfClasses,log,shareList, initialDate)

% Settings:
%initialDate = (datetime('today')-(calyears(19)+caldays(1)));
finalDate = (datetime('today')-caldays(90));
%shareList = {'EUR=X','CAD=X'};
%windowSize = 5;%Days
%numberOfClasses = 3;
%log = true;
dataSetParameters = {'$Change','$Volatility','Open','Close'};
graph = true;



% --- DOWNLOAD DATA ---
if log
    disp('DOWNLOADING...')
end

% Create Empty Table for Data
dateArray = initialDate:finalDate;
[y,m,d] = datevec(dateArray);
marketData = array2table([y;m;d], 'RowName', {'Year','Month','Day'});
% Loop Through Each Symbol
for shares = 1:length(shareList)
    rawData = getMarketDataViaYahoo(shareList{shares}, initialDate, finalDate, '1d');
    
    % Extend Table for Symbol
    for i=1:length(dataSetParameters)
        marketData=[marketData; array2table(zeros(size(y)))];
        marketData.Properties.RowNames{end}=append(shareList{shares},'-',dataSetParameters{i});
    end
    
    % Conver the Date to Three Seperate Values
    [yy,mm,dd] = datevec(rawData.Date);
    Tdate = table(yy,mm,dd,'VariableName',{'Year','Month','Day'});
    data = [Tdate,rawData(:,{'Open','High','Low','Close','AdjClose','Volume'})];
    
    
    % Sync Tables
    data.Change = diff(data{:,{'Open','Close'}},1,2);
    data.Volatility = diff(data{:,{'Low','High'}},1,2);
    for date=1:length(data{:,1})
        dateDifference = split(caldiff([initialDate,rawData.Date(date)],'days'),'days');
        estimatedColumn=dateDifference+1;
        if marketData{'Day',estimatedColumn}==data{date,'Day'} & marketData{'Month',estimatedColumn}==data{date,'Month'} & marketData{'Year',estimatedColumn}==data{date,'Year'}
            marketData{append(shareList{shares},'-','$Change'),estimatedColumn}=data{date,'Change'};
            marketData{append(shareList{shares},'-','$Volatility'),estimatedColumn}=data{date,'Volatility'};
            %marketData{append(shareList{shares},'-','Volume'),estimatedColumn}=data{date,'Volume'};
            marketData{append(shareList{shares},'-','Open'),estimatedColumn}=data{date,'Open'};
            marketData{append(shareList{shares},'-','Close'),estimatedColumn}=data{date,'Close'};
        else
            fprintf('%s Date Mismatch at %d/%d/%d!\n', string(shareList{shares}), marketData{'Day',date}, marketData{'Month',date}, marketData{'Year',date})
        end
    end
    
    
    if log
        % Progress Indicator
        progress=floor(shares/length(shareList)*100);
        fprintf('%0.0f%% - (%s Downloaded)\n', progress, shareList{shares})
    end
end
% Delete Days With No Data
for date=length(marketData{1,:}):-1:1
    empty=true;
    if marketData{append(shareList{1},'-Close'),date}~=0
        empty=false;
    end
    %{
    Uncomment to include days where main symbol is empty
    for shares = 1:length(shareList)
        if marketData{append(shareList{shares},'-','$Change'),date}~=0
            empty=false;
        end
    end
    %}
    if empty
        marketData(:,date) = [];
    end
end
fprintf('%i Days Out of the %i With No Trade Info!\n',(length(y)-length(marketData{1,:})),length(y))



% --- PRODUCE GRAPH ---
if graph
    if log
        disp('GRAPHING...')
    end
    figure('Name','Symbols Overview');
    graphArray={((marketData{'Year',:}*365+marketData{'Month',:}*31+marketData{'Day',:})/365),marketData{append(shareList{1},'-','Close'),:}};
    for shares = 2:length(shareList)
        graphArray={graphArray{:,:},((marketData{'Year',:}*365+marketData{'Month',:}*31+marketData{'Day',:})/365),marketData{append(shareList{shares},'-Close'),:}};
    end
    plot(graphArray{1,:})
    title('Symbols Overview')
    xlabel('Year')
    ylabel('Price in $')
    legend(shareList)

    % Daily Change Distribution
    figure('Name','Price Change Distribution');
    graphArray=marketData{append(shareList{1},'-','Open'),:}-marketData{append(shareList{1},'-','Close'),:};
    for i = 1:(width(marketData)-1)
        graphArray(i)=marketData{append(shareList{1},'-','Close'),i+1}-marketData{append(shareList{1},'-','Close'),i};
    end
%for shares = 2:length(shareList)
%    horzcat(graphArray,marketData{append(shareList{shares},'_DailyChange'),:});
%end
    histogram(graphArray)
    title('Price Change Distribution')
    xlabel('Daily Price Change in $')
    ylabel('Number of Samples (Days)')
    graphArray=sort(graphArray);
    singleClassSize=floor(length(graphArray)/numberOfClasses);
    if log
        disp('Example Classes Could Be:')
    end
    for i=1:(numberOfClasses-1)
        if log
            fprintf('%i: %.2f$ - %.2f$ (with %i Samples)\n', i, graphArray(((i-1)*singleClassSize)+1), graphArray(i*singleClassSize), singleClassSize)
        end
        if i == 1
            exampleClasses(i,1:2)={(graphArray(((i-1)*singleClassSize)+1)-1),graphArray(i*singleClassSize)};
        else
            exampleClasses(i,1:2)={graphArray(((i-1)*singleClassSize)+1),graphArray(i*singleClassSize)};
        end
    end
    if log
        fprintf('%i: %.2f$ - %.2f$ (with %i Samples)\n', numberOfClasses, graphArray(((numberOfClasses-1)*singleClassSize)+1), graphArray(end), (length(graphArray)-(singleClassSize*(numberOfClasses-1))))
    end
    exampleClasses(numberOfClasses,1:2)={graphArray(((numberOfClasses-1)*singleClassSize)+1),(graphArray(end)+1)};
end



% --- SORT DATA ---
if log
    disp('SORTING...')
end
% Add the Output (i.e. whether the price goes up next day)
dataSet = cell2table(cell(0,2)); dataSet.Properties.VariableNames={'Input','Output'};
progcounter=0;
for i=1:numberOfClasses
    if all(cell2mat(exampleClasses(i,:)) > 0)
        classes(1,i)=append(string(i),'_Up');
        classes(2,i)=0;
    elseif any(cell2mat(exampleClasses(i,:)) > 0)
        classes(1,i)=append(string(i),'_No_Change');
        classes(2,i)=0;
    else
        classes(1,i)=append(string(i),'_Down');
        classes(2,i)=0;
    end
end
for marketDateCounter = windowSize:(length(marketData{1,:})-1)
    % Categorise Price Change
    priceChange=marketData{append(shareList{1},'-','Close'),(marketDateCounter+1)}-marketData{append(shareList{1},'-','Close'),(marketDateCounter)};
    notFound=true;
    while notFound
        for i=1:numberOfClasses
            if priceChange <= cell2mat(exampleClasses(i,2)) & priceChange >= cell2mat(exampleClasses(i,1))
                className=classes(1,i);
                dataSet=[dataSet;cell2table({marketData(:,(1+marketDateCounter-windowSize):marketDateCounter),className},'VariableNames',{'Input','Output'})];
                notFound=false;
            end
        end
    end
    
    if log
        % Progress Indicator
        progress=floor(marketDateCounter/(length(marketData{1,:})-1)*100);
        if progcounter < progress
            fprintf('%i%% - (%d Data Points Sorted)\n', progress, (marketDateCounter))
            progcounter=progcounter+9;
        end
    end
end



% --- STORE DATA ---
if log
    disp('STORING...')
end
progcounter=0;
%classes={'High_Up','Up','No_Change','Down','Low_Down';0,0,0,0,0};
cd '../';cd '../';%Keep it out of MATLAB Drive
% Create Directory
if ~exist('Dataset', 'dir')
    mkdir('Dataset');
    cd 'Dataset';
else
    if log
        disp('Dataset Directory Already Exists!')
        disp('Deleting Previous Data...')
    end
    rmdir 'Dataset' s;
    mkdir('Dataset');
    cd 'Dataset';
end

for classCounter = 1:length(classes(1,:))
    mkdir(string(classes(1,classCounter)));
end
for datapoint = 1:(length(dataSet{:,1}))
    % Update Statistics
    classNameLocation=find(classes(1,:)==string(dataSet{datapoint,2}));
    classes(2,classNameLocation)=str2num(classes(2,classNameLocation))+1;
    % Save File
    cd(string(dataSet{datapoint,2}));
    writetable(dataSet{datapoint,1}{1,1},append(string(dataSet{datapoint,2}),'_',string(classes{2,classNameLocation}),'.csv'),'WriteRowNames',true,'WriteVariableNames',false);
    cd '../';
    
    if log
        % Progress Indicator
        progress=floor(datapoint/length(dataSet{:,1})*100);
        if progcounter < progress
            fprintf('%i%% - (%d Files Saved)\n', progress, (datapoint))
            progcounter=progcounter+9;
        end
    end
end
%Normalise Data
[minVal,minPos]=min(str2double(classes(2,:)));
for i=1:length(classes(1,:))
    cd(string(classes(1,i)));
    fileNames=dir;fileNames=fileNames(~[fileNames.isdir]); fileNames={fileNames.name};
    for ii=(minVal+1):length(fileNames)
        delete(append(string(classes(1,i)),'_',string(ii),'.csv'))
    end
    classes(2,i)=minVal;
    cd '../';
end

cd '../';
if log
    disp('Finished! Created:')
    for classCounter=1:length(classes(1,:))
        fprintf('%s %s Data Points\n', classes(2,classCounter), classes(1,classCounter))
    end
    fprintf('Normalised to %i files per class\n',minVal)
end
%cd 'MATLAB Drive/Testing Area'; %Windows
cd 'MATLAB-Drive/Testing Area'; %macOS

%end
