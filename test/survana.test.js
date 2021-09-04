const { assert } = require('chai');

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

contract("Survana", async function ([deployer, creator, userA]) {
  let token, survana
  before(async () => {
    // token = await Token.deployed("0xAB932896E755Fc63122fC99AE9c0c219D0b55991")
    survana = await Survana.new("0xAB932896E755Fc63122fC99AE9c0c219D0b55991")
  
    //send some tokens to the creator (100M)
    // token.transfer(creator, toWei('100'), {from: deployer})
  })

  describe("Deployment", () => {
    it("Should have a name", async () => {
      const name = await survana.name()
      assert.equal(name, "Survana")
    })

    it("Should have a token address", async () => {
      const token = await survana.token()
      assert.equal(token, "0xAB932896E755Fc63122fC99AE9c0c219D0b55991")
    })
  })

  describe("Creator Functions", () => {
    it("Should be able to add a creator", async () => {
      const result = await survana.addCreator(creator)
      const event = result.logs[0].args
      // console.log(event)
      assert.equal(event._creator, creator)
      const check = await survana.creators(creator)
      assert.equal(check,true)
    })

    it("Should be able to remove a creator", async () => {
      await survana.addCreator(userA)
      const result = await survana.removeCreator(userA)
      const event = result.logs[0].args
      assert.equal(event._creator, userA)
      const check = await survana.creators(userA)
      assert.equal(check,false)
    })

    it("Should be able to create a survey", async () => {
      const result = await survana.createSurvey("First Survey", "This is the first survey", toWei("100"), {from: creator})
      const event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)

      //make sure the address is stored in the surveys variable
      const address = await survana.surveys(0)
      // console.log(address);
      assert.isNotNull(address)

      //now grab that address using the grab function
      const surveys = await survana.getCreatorSurveys({from: creator})
      // console.log(surveys.logs[0].args)
      // console.log(surveys)
      assert.isArray(surveys)
      assert.equal(surveys[0].name, 'First Survey')
      assert.equal(surveys[0].bonusAmount.toString(), toWei("100").toString())
    })

    it ("Should be able to update the survey", async () => {
      // const res = await survana.creators(creator)
      // console.log(res)
      //make sure the address is stored in the surveys variable
      const address = await survana.surveys(0)
      assert.isNotNull(address)
      console.log(address)

      //change change the description to something else and make sure it stuck
      //first fetch the open survey
      let surveys = await survana.getCreatorSurveys({from: creator})
      const survey = surveys[0]
      console.log(survey)

      //now modify the description to "My updated first survey"
      const newDesc = "My updated first survey"
      const result = await survana.updateSurvey(0, survey.name, newDesc, survey.bonusAmount, {from: creator})
      console.log(result)
      const event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)
      assert.equal(event._contract, address)

      surveys = await survana.getCreatorSurveys({from: creator})
      assert.isArray(surveys)
      assert.equal(surveys[0].description, newDesc)
    })

    it("Should be able to add questions to the survey", async () => {
      //add two questions for this test and make sure both are listed
    })

    //do withdraw/deposits last in this group
  })

  //finish transfer the tokens back
  // after(async() => {
  //   //get remainder
  //   let bal = await token.balanceOf(creator)
  //   if (bal > 0) {
  //     token.transfer(deployer, bal, {from: creator})
  //   }
  //   bal = await token.balanceOf(userA)
  //   if (bal > 0) {
  //     token.transfer(deployer, bal, {from: userA})
  //   }
  // })
})
