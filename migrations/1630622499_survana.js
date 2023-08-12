const Survana = artifacts.require("Survana");
// const Token = artifacts.require("Token");

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  //OLD//
  //0x328F2d2D54D2A406c9536993195bA8B8eBABD2Cf <- live address
  //0x93DAcc9cA3CfAdA36Cd927223521fA7715351812 <- local address
  ///////

  //NEW//
  //0x56f3cB9C0869f5939A3D6918793539c11A87C424 <- live address
  ///////
  _deployer.deploy(Survana, "0x56f3cB9C0869f5939A3D6918793539c11A87C424");
};
