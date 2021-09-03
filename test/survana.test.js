const Survey = artifacts.require("Survey");
const Survana = artifacts.require("Survana");
const Token = artifacts.require("Token");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */

require('chai')
  .use(require('chai-as-promised'))
  .should()

const toWei = (n) => {
    return web3.utils.toWei(n, "ether")
}

const fromWei = (n) => {
    return web3.utils.fromWei(n, "ether")
}

contract("Survana", async function ([deployer, creator, userA, userB]) {
  const token = await Token.new()
  const survana = await Survana.new(token.address)
  
  //send some tokens to the creator (100M)
  await token.transfer(creator, toWei("100000000"))

  describe("Deployment", () => {
    it("Should have a name", async () => {
      const name = await survana.name()
      assert.equal(name, "Survana")
    })
  })
})
