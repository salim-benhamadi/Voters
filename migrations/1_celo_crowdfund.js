const CeloElection = artifacts.require("CeloElection");

module.exports = function (deployer) {
  deployer.deploy(CeloElection);
};
