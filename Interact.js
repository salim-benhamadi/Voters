const Web3 = require("web3");
const ContractKit = require("@celo/contractkit");
const web3 = new Web3("https://alfajores-forno.celo-testnet.org");
const kit = ContractKit.newKitFromWeb3(web3);
const CeloElection = require("./build/contracts/CeloElection.json");
const Election = require("./build/contracts/Election.json");

require("dotenv").config({ path: ".env" });

let account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
kit.connection.addAccount(account.privateKey);

async function createElection(celoElectionContract, stableToken) {
  await celoElectionContract.methods
    .startElection(
      stableToken.address,
      1222,
      "First election",
      "We are testing the create election function",
      "https://i.imgur.com/Flfo4hJ.png",
      220,
      10,
      10
    )
    .send({ from: account.address });

  console.log(" ++++++++++ Created a new election +++++++++++");
}

async function addCondidate(electionInstanceContract) {
  await electionInstanceContract.methods.addCandidate("Salim ben hammadi");

  console.log("+++++++++++++ condidate added ! ++++++++++++++ \n");
}

async function vote(electionInstanceContract, candidateId) {
  await electionInstanceContract.methods.vote(candidateId);
  console.log("+++++++++++++ Voted ++++++++++++++ \n");
}

async function interact() {
  // Check the Celo network ID
  const networkId = await web3.eth.net.getId();
  // Get the contract associated with the current network
  const deployedNetwork = await CeloElection.networks[networkId];

  // Create a new contract instance from the celo election contract
  let celoElectionContract = new kit.web3.eth.Contract(
    CeloElection.abi,
    deployedNetwork && deployedNetwork.address
  );

  // Print wallet address so we can check it on the block explorer
  console.log("Account address: ", account.address);

  // Get the cUSD ContractKit wrapper
  var stableToken = await kit.contracts.getStableToken();

  await createElection(celoElectionContract, stableToken);

  // Return elections inside the celo election contract
  var result = await celoElectionContract.methods.returnElections().call();
  console.log(
    "List of addressses for each of the election created:",
    result.length
  );

  var electionInstanceContract = new web3.eth.Contract(
    Election.abi,
    deployedNetwork && result[result.length - 1] // Get the most recently deployed election
  );

  await addCondidate(electionInstanceContract);

  await vote(electionInstanceContract, 1);
}

interact();
