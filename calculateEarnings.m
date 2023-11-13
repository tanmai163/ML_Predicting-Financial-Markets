% Calculate Model Earnings
% Coventry University - Individual Project
% 12/01/2021
% Paul Johannes Aru



function [wallet,statArray] = calculateEarnings(model,windowSize,log,shareList, miniBatchSize)

% Settings:
initialDate = (datetime('today')-caldays(90));
finalDate = datetime('today');
%shareList = {'KO','^GSPC'};
%windowSize = 30;%Days
%log = true;
%miniBatchSize = 1683;
dataSetParameters = {'$Change','$Volatility','Open','Close'};



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
    if marketData{append(shareList{1},'-','Close'),date}~=0
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



% --- SORT DATA ---
if log
    disp('SORTING...')
end
% Add the Output (i.e. whether the price goes up next day)
dataSet = cell2table(cell(0,2)); dataSet.Properties.VariableNames={'Input','Output'};
progcounter=0;

for marketDateCounter = windowSize:(length(marketData{1,:})-1)
    % Categorise Price Change
    priceChange=marketData{append(shareList{1},'-Close'),(marketDateCounter+1)}-marketData{append(shareList{1},'-Close'),(marketDateCounter)};
    notFound=true;
    futurePrice=marketData{append(shareList{1},'-Close'),(marketDateCounter+1)};
    dataSet=[dataSet;cell2table({table2array(marketData(:,(1+marketDateCounter-windowSize):marketDateCounter)),futurePrice},'VariableNames',{'Input','Output'})];
    
    if log
        % Progress Indicator
        progress=floor(marketDateCounter/(length(marketData{1,:})-1)*100);
        if progcounter < progress
            fprintf('%i%% - (%d Data Points Sorted)\n', progress, (marketDateCounter))
            progcounter=progcounter+9;
        end
    end
end



% --- SIMULATE MODEL ---
if log
    disp('SIMULATING...')
end
% Split Input & Output for LSTM
inputTestData=dataSet{:,1};
outputTestData=dataSet{:,2};
simulationPrediction = classify(model,inputTestData,'MiniBatchSize',miniBatchSize);
wallet=0;
for i=1:(length(dataSet{:,1}))
    if i == 1
        purchasePrice=inputTestData{i,1}(7,end);
        wallet=wallet-(5*purchasePrice);
        sharesOwned=5;
    elseif contains(string(simulationPrediction(i)),"Up");
        purchasePrice=inputTestData{i,1}(7,end);
        wallet=wallet-(purchasePrice);
        sharesOwned=sharesOwned+1;
    elseif contains(string(simulationPrediction(i)),"Down");
        sellPrice=outputTestData(i,1);
        wallet=wallet+(sellPrice);
        sharesOwned=sharesOwned-1;
    end
    if i == length(dataSet{:,1})
        sellPrice=outputTestData(i,1);
        wallet=wallet+(sharesOwned*sellPrice);
        sharesOwned=0;
    end
end
statArray={simulationPrediction,outputTestData};
if log
    fprintf('Finished!\nWe made: %.2f$\n', (wallet))
end

end