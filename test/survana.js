const Survana = artifacts.require("Survana");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("Survana", function (/* accounts */) {
  it("should assert true", async function () {
    await Survana.deployed();
    return assert.isTrue(true);
  });
});
