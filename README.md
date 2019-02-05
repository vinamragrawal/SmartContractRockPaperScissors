# RockPaperScissors
Smart contract based on "Rock, paper scissors" Game.

Follow the steps below to download, install, and run this application.

## Dependencies
Install these prerequisites.
- NPM: https://nodejs.org
- Truffle: https://github.com/trufflesuite/truffle
- Ganache: http://truffleframework.com/ganache/
- Metamask: https://metamask.io/

## Step 1. Clone the project
`git clone https://github.com/vinamragrawal/SmartContractRockPaperScissors.git`

## Step 2. Install Node dependencies
```
$ cd RockPaperScissors
$ npm install
```
## Step 3. Start Ganache Application
Open the Ganache GUI client that you downloaded and installed to start your local blockchain instance.

## Step 4. Compile & Deploy the Smart Contract locally
`$ truffle migrate --reset`
You must migrate(deploy) the contract each time you start a new Ganache instance.

## Step 5. Configure Metamask
- Connect metamask to your local Etherum blockchain provided by Ganache.
- Import an account provided by ganache.

## Step 6. Run the Front End Application
`$ npm run dev`
Visit this URL in your browser: http://localhost:3000
