const Survana = artifacts.require("Survana");
// const Token = artifacts.require("Token");

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(Survana, "0x0a222cA4166A6a4Ee4D4A019b1001bca151723C9");
};
