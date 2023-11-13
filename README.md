# Project Scripts

###### Updated: 29/04/2021

These MATLAB Files Will Enable You to Train Your Own Neural Network for Predicting a Financial Market!

## `getMarketDataViaYahoo.m`

Clone of a [MATLAB Function](https://github.com/Lenskiy/Yahoo-Quandl-Market-Data-Donwloader) created by [Artem Lensky](https://github.com/Lenskiy) from GitHub.

## `downloadSequencedTrainingData.m`

- `windowSize` - **The Data Point Window Size in Days** (e.g. 1 = Current Day, 7 = Week Leading Up, etc...)
- `numberOfClasses` - **The Number of Classes the Dataset Will be Split Into** (e.g. 3 = Up, No-Change, Down; 5 = High Up, Up, No-C...; etc...)
- `log` - **Enables More Detailed Progress Communication in the *Command Window*** (e.g. true, false)
- `shareList` - **A List of (*Yahoo Finance Compatible*) Symbols for the Dataset to Use** (e.g. {'EUR=X'}, {'INTC','^GSPC'}, etc...)
- `initialDate` - ***datetime* Value Indicating the Starting Date for the Dataset** (e.g. datetime('today')-(calyears(5)+caldays(1)), datetime(2020,09,10), etc...)
- *return* -  **String Matrix, Where the First Row Contains Class Names and the Second Row Contains the Number of Data Points in the Above Class**.

## `createLSTM.m`

- `log` - **Enables More Detailed Progress Communication in the *Command Window*** (e.g. true, false)
- `numHiddenUnits` - **The Number of Hidden Units in the LSTM Layer of our Model** (e.g. 100, 1500, etc...)
- `maxEpochs` - **The Epoch Limit Value for Training the Model** (e.g. 5000, 10000, etc...)
- `miniBatchSize` - **The Batches that the Dataset Will Be Split Into During the Training Process** (e.g. 1500, 1000, etc..)
- *return* - [**The Trained Model**, **Precise Accuracy Percentage**, **Directional Accuracy Percentage**]

## `calculateEarnings.m`

- `model` - **The Trained Model that we Wish to Simulate**
- `windowSize` - **The Data Point Window Size in Days** (e.g. 1 = Current Day, 7 = Week Leading Up, etc...)
- `log` - **Enables More Detailed Progress Communication in the *Command Window*** (e.g. true, false)
- `shareList` - **A List of (*Yahoo Finance Compatible*) Symbols for the Dataset to Use** (e.g. {'EUR=X'}, {'INTC','^GSPC'}, etc...)
- `miniBatchSize` - **The Batches that the Dataset Was Split Into During the Training Process** (e.g. 1500, 1000, etc..)
- *return* - [**Simulated Earnings**, **Array of Cells with Simulation Decisions and Market Price**]

## `batchProcess.m`

Simple Script that Enables Batch Model Testing. Calls the Above Functions In Order as it Loops Through Previously Assigned Parameters. Creates a Log File Detailing the Results.