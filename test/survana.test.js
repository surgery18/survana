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

contract("Survana", async function ([deployer, creator, userA, userB, userC]) {
  let token, survana
  const tokenAddr = "0x93DAcc9cA3CfAdA36Cd927223521fA7715351812"
  before(async () => {
    token = await Token.at(tokenAddr)
    survana = await Survana.new(tokenAddr)
  })

  describe("Deployment", () => {
    it("Should have a name", async () => {
      const name = await survana.name()
      assert.equal(name, "Survana")
    })

    it("Should have a token address", async () => {
      const token = await survana.token()
      assert.equal(token, tokenAddr)
    })
  })

  describe("Creator Survey Creation", () => {
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

      //there should be 2 addresses now in the surveys
      assert.equal(await survana.surveyCount(), 1)
      assert.equal(await survana.creatorSurveyCount(creator), 1)

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
      // console.log(address)

      //change change the description to something else and make sure it stuck
      //first fetch the open survey
      let surveys = await survana.getCreatorSurveys({from: creator})
      const survey = surveys[0]
      // console.log(survey)

      //now modify the description to "My updated first survey"
      const newDesc = "My updated first survey"
      const result = await survana.updateSurvey(0, survey.name, newDesc, survey.bonusAmount, {from: creator})
      // console.log(result)
      const event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)
      assert.equal(event._contract, address)

      surveys = await survana.getCreatorSurveys({from: creator})
      assert.isArray(surveys)
      assert.equal(surveys[0].description, newDesc)
    })

    it("Should be able to add questions to the survey", async () => {
      const address = await survana.surveys(0)
      assert.isNotNull(address)

      //add two questions for this test and make sure both are listed
      let result = await survana.addQuestion(
        0,
        0,
        toWei("10"),
        true,
        "Question 1",
        "What is 1+1?",
        ["1", "2", "3", "4"],
        {from: creator}
      )
      let event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._contract, address)
      assert.equal(event._surveyId, 0)
      assert.equal(event._questionId, 0)

      result = await survana.addQuestion(
        0,
        2,
        toWei("50"),
        false,
        "Question 2",
        "Explain the meaning of life",
        [],
        {from: creator}
      )
      event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._contract, address)
      assert.equal(event._surveyId, 0)
      assert.equal(event._questionId, 1)

      //load survey
      const s = await Survey.at(await survana.surveys(0))

      //questions should be 2
      assert.equal(await s.questionCount(), 2)
      
      //now check the questions
      const questions = await s.getQuestions()
      assert.isArray(questions)
      assert.lengthOf(questions, 2)
      //console.log(questions)
      const q1 = questions[0]
      const q2 = questions[1]
      //check each field to see if it was set correctly

      assert.equal(q1.questionType, '0')
      assert.equal(q1.worth, toWei("10"))
      assert.equal(q1.required, true)
      assert.equal(q1.title, "Question 1")
      assert.equal(q1.description,  "What is 1+1?")
      assert.isArray(q1.choices)
      assert.lengthOf(q1.choices, 4)
      //just take a random one
      assert.equal(q1.choices[2], '3')


      assert.equal(q2.questionType, '2')
      assert.equal(q2.worth, toWei("50"))
      assert.equal(q2.required, false)
      assert.equal(q2.title, "Question 2")
      assert.equal(q2.description,  "Explain the meaning of life")
      assert.isArray(q2.choices)
      assert.lengthOf(q2.choices, 0)
    })

    it("Should be able to update a questions to the survey", async () => {
      const address = await survana.surveys(0)
      assert.isNotNull(address)

      const result = await survana.updateQuestion(
        0,
        1,
        2,
        toWei("100"),
        false,
        "Question 2",
        "Explain why you will not take the vaccine?",
        [],
        {from: creator}
      )
      const event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._contract, address)
      assert.equal(event._surveyId, 0)
      assert.equal(event._questionId, 1)

      //load survey
      const s = await Survey.at(await survana.surveys(0))

      //questions should be 2
      assert.equal(await s.questionCount(), 2)
      
      //now check the questions
      const questions = await s.getQuestions()
      assert.isArray(questions)
      assert.lengthOf(questions, 2)
      //console.log(questions)
      const q2 = questions[1]
      //check each field to see if it was set correctly
      assert.equal(q2.questionType, '2')
      assert.equal(q2.worth, toWei("100"))
      assert.equal(q2.required, false)
      assert.equal(q2.title, "Question 2")
      assert.equal(q2.description,  "Explain why you will not take the vaccine?")
      assert.isArray(q2.choices)
      assert.lengthOf(q2.choices, 0)
    })

    it("Should be able to add another survey with a question", async () => {
      let result = await survana.createSurvey("2nd Survey", "This is the 2nd survey", 0, {from: creator})
      let event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 1)

      //there should be 2 addresses now in the surveys
      assert.equal(await survana.surveyCount(), 2)
      assert.equal(await survana.creatorSurveyCount(creator), 2)

      //make sure the address is stored in the surveys variable
      const address = await survana.surveys(1)
      assert.isNotNull(address)

      //now grab that address using the grab function
      const surveys = await survana.getCreatorSurveys({from: creator})
      assert.isArray(surveys)
      assert.equal(surveys[1].name, '2nd Survey')
      assert.equal(surveys[1].bonusAmount.toString(), toWei("0").toString())

      //just to be sure add a question to it
      result = await survana.addQuestion(
        1,
        0,
        toWei("10"),
        true,
        "Q1",
        "What is after A?",
        ["B", "C", "D", "E"],
        {from: creator}
      )
      event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._contract, address)
      assert.equal(event._surveyId, 1)
      assert.equal(event._questionId, 0)

      //load survey
      const s = await Survey.at(await survana.surveys(1))
      assert.equal(await s.questionCount(), 1)

      //then it should fetch back 2 surveys
      const surv = await survana.getCreatorSurveys({from: creator})
      assert.isArray(surv)
      assert.lengthOf(surv, 2)
    })

    it("Should not let normal users add a survey", async() => {
      await survana.createSurvey("3rd Survey", "This is the 3rd survey", toWei("100"), {from: userA}).should.be.rejected
    })

    it("Should not let normal users update a survey", async() => {
      await survana.updateSurvey(0, "Foo", "Bar", toWei("1"), {from: userA}).should.be.rejected
    })

    it("Should not let normal users add a question", async() => {
      await survana.addQuestion(
        1,
        0,
        toWei("1000"),
        true,
        "Q1-FOO",
        "What is after A?- BAR",
        ["B", "C", "D", "E"],
        {from: userA}
      ).should.be.rejected
    })

    it("Should not let normal users update a question", async() => {
      await survana.updateQuestion(
        0,
        1,
        2,
        toWei("1000"),
        false,
        "Question 2 - BLAG",
        "Explain why you will not take the vaccine? - STUFF",
        [],
        {from: userA}
      ).should.be.rejected
    })

    it("Should be able to deposit tokens into the survey", async() => {
      //user has to approve the contract taking funds from their account
      //lets deposit 250 tokens into the first survey and 100 tokens into the other survey
      const amountA = toWei("500")
      const amountB = toWei("15")
      const s1 = await survana.surveys(0)
      await token.approve(s1, amountA, {from: creator})
      const s2 = await survana.surveys(1)
      await token.approve(s2, amountB, {from: creator})
      //now  deposit into each survey
      let result = await survana.depositToSurveyTokenPool(0, amountA, {from: creator})
      let event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)
      assert.equal(event._amount.toString(), amountA.toString())
      result = await survana.depositToSurveyTokenPool(1, amountB, {from: creator})
      event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 1)
      assert.equal(event._amount.toString(), amountB.toString())
      

      //now we will check the balances of each contract
      let balance = await token.balanceOf(s1)
      assert.equal(balance.toString(), amountA)

      balance = await token.balanceOf(s2)
      assert.equal(balance.toString(), amountB)

      //then we will check the uint of the struct of each contract
      let s = await Survey.at(s1)
      let pool = await s.pool()
      assert.equal(pool.tokenAmount, amountA)

      s = await Survey.at(s2)
      pool = await s.pool()
      assert.equal(pool.tokenAmount, amountB)
    })

    it("Should be able to deposit gas money into the survey", async() => {
      //lets only add gass to the 1st survey
      // const s = await survana.surveys(0)
      let result = await survana.depositToSurveyGasPool(0, {from: creator, value: toWei("0.1")})
      let event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)
      assert.equal(event._amount.toString(), toWei("0.1").toString())
      //get the balance of the contract
      const s1 = await survana.surveys(0)
      balance = await web3.eth.getBalance(s1)
      assert.equal(balance.toString(), toWei("0.1").toString())
    })

    it("Should not let users deposit tokens into the survey", async () => {
      await survana.depositToSurveyTokenPool(0, toWei("250"), {from: userA}).should.be.rejected
    })

    it("Should not let users deposit gas into the survey", async () => {
      await survana.depositToSurveyGasPool(0, {from: userA, value: toWei("0.1")}).should.be.rejected
    })

    it("Should be able to change the surveys statuses", async () => {
      //make sure there is nothing in the open surveys
      let surveys = await survana.getOpenSurveys({from: userA})
      // console.log(surveys)
      assert.isArray(surveys)
      assert.lengthOf(surveys, 0)

      //open up both surveys
      let result = await survana.setSurveyStatus(0, 1, {from: creator})
      let event = result.logs[0].args
      assert.equal(event._status, 1)
      assert.equal(event._id, 0)

      result = await survana.setSurveyStatus(1, 1, {from: creator})
      event = result.logs[0].args
      assert.equal(event._status, 1)
      assert.equal(event._id, 1)

      //now a user should be able to poll both of them
      surveys = await survana.getOpenSurveys({from: userA})
      assert.isArray(surveys)
      assert.lengthOf(surveys, 2)

      //the creator should see 0 open surveys
      surveys = await survana.getOpenSurveys({from: creator})
      assert.isArray(surveys)
      assert.lengthOf(surveys, 0)

    })
  })

  describe("Submitting A Survey", () => {
    it("Should let a normal user submit a survey and give back tokens and gas", async () => {
      //test completion
      const s1 = await survana.surveys(0)
      const survey = await Survey.at(s1)
      const oldPool = await survey.pool()
      const oldBal = await survey.getBalance()

      let worth = await survey.worth()
      const ba = await survey.bonusAmount()
      worth = worth.add(ba)
      // try {
      let result = await survana.submitSurvey(0, ["1", "N/A"], {from: userA})
      // console.log(result.logs)
      // } catch(e) {
      //   console.log(e)
      // }
      let event = result.logs[0].args
      assert.equal(event._user, userA)
      assert.equal(event._surveyId, 0)
      assert.equal(event._tokensAwarded.toString(), worth)

      //that amount should have been subtracted from the survey
      const newPool = await survey.pool()
      assert.isBelow(+fromWei(newPool.tokenAmount), +fromWei(oldPool.tokenAmount))
      assert.isBelow(+fromWei(newPool.gasAmount), +fromWei(oldPool.gasAmount))
      
      //and added to the sent variable
      assert.isAbove(+fromWei(newPool.totalTokensSent), +fromWei(oldPool.totalTokensSent))
      assert.isAbove(+fromWei(newPool.totalGasSent), +fromWei(oldPool.totalGasSent))

      //now make sure the balance is different as well
      const newBal = await survey.getBalance()
      assert.notEqual(oldBal.toString(), newBal.toString())
    })

    it("Should let a normal user submit a survey and give back tokens and no gas and close the survey", async () => {
      const s2 = await survana.surveys(1)
      const survey = await Survey.at(s2)
      const oldPool = await survey.pool()
      const oldBal = await survey.getBalance()

      let worth = toWei("10")
      let result = await survana.submitSurvey(1, ["0"], {from: userA})
      let event = result.logs[0].args
      assert.equal(event._user, userA)
      assert.equal(event._surveyId, 1)
      assert.equal(event._tokensAwarded.toString(), worth)

      //that amount should have been subtracted from the survey
      const newPool = await survey.pool()
      // console.log(newPool)
      assert.isBelow(+fromWei(newPool.tokenAmount), +fromWei(oldPool.tokenAmount))
      assert.equal(+fromWei(newPool.gasAmount), +fromWei(oldPool.gasAmount))
      
      //and added to the sent variable
      assert.isAbove(+fromWei(newPool.totalTokensSent), +fromWei(oldPool.totalTokensSent))
      assert.equal(+fromWei(newPool.totalGasSent), +fromWei(oldPool.totalGasSent))

      //now make sure the balance is different as well
      const newBal = await survey.getBalance()
      assert.equal(oldBal.toString(), newBal.toString())

      //should be closed
      const status = await survey.status()
      assert.equal(status, 2)
    })

    it("Should not give bonus token if survey is not complete", async () => {
       //ONLY CHECK TOKENS.
       const s1 = await survana.surveys(0)
       const survey = await Survey.at(s1)
       const oldPool = await survey.pool()
       const oldBal = await survey.getBalance()
 
       let worth = toWei("10")
       // try {
       let result = await survana.submitSurvey(0, ["1", ""], {from: userB})
       // console.log(result.logs)
       // } catch(e) {
       //   console.log(e)
       // }
       let event = result.logs[0].args
       assert.equal(event._user, userB)
       assert.equal(event._surveyId, 0)
       assert.equal(event._tokensAwarded.toString(), worth)
 
       //that amount should have been subtracted from the survey
       const newPool = await survey.pool()
       assert.isBelow(+fromWei(newPool.tokenAmount), +fromWei(oldPool.tokenAmount))
       
       //and added to the sent variable
       assert.isAbove(+fromWei(newPool.totalTokensSent), +fromWei(oldPool.totalTokensSent))
    })

    it("Should fail if given a required question null", async () => {
      await survana.submitSurvey(0, ["", ""], {from: userC}).should.be.rejected
    })

    it("Should not let the creator take their own survey", async () => {
      await survana.submitSurvey(0, ["1", "FOOBAR"], {from: creator}).should.be.rejected
    })

    it("Should not let a user submit a closed survey", async () => {
      //this one is closed from a previous test
      await survana.submitSurvey(1, ["FOOBAR"], {from: userC}).should.be.rejected
    })

    it("Should fail if array length does not match the number of questions", async () => {
      await survana.submitSurvey(0, ["1"], {from: userC}).should.be.rejected
      await survana.submitSurvey(0, ["1", "FOO", "BAR"], {from: userC}).should.be.rejected
    })

    it("Should not let a user submit a survey they already took", async () => {
      await survana.submitSurvey(0, ["1", "BLAGGERS"], {from: userA}).should.be.rejected
    })

    it("Should not let a user submit a pending survey", async () => {
      //create another survey
      await survana.createSurvey("3rd Survey", "This survey will stay pending", 0, {from: creator})

      //just to be sure add a question to it
      await survana.addQuestion(
        2,
        0,
        toWei("10"),
        true,
        "Q1",
        "Is the world flat?",
        ["YES", "NO"],
        {from: creator}
      )

      //now try to submit an answer to this survey
      await survana.submitSurvey(2, ["0"], {from: userA}).should.be.rejected
    })

    it("Should not let you vote for a non-existant survey", async () => {
      await survana.submitSurvey(100, ["0"], {from: userA}).should.be.rejected
    })

    it("Should show the compeleted surveys that the user took", async() => {
      const surveys = await survana.getUserFinishedSurveys({from: userA})
      assert.isArray(surveys)
      assert.lengthOf(surveys, 2)
    })
  })

  describe("Withdraw functions", () => {
    //test rejections first
    it("Should not let a normal user withdraw the tokens pool", async () => {
      await survana.withdrawFromTokenPool(0, toWei('1'), {from: userA}).should.be.rejected
    })

    it("Should not let a normal user withdraw the gas pool", async () => {
      await survana.withdrawFromGasPool(0, toWei('0.01'), {from: userA}).should.be.rejected
    })

    it("Should let the creator to withdraw the remaing tokens pool", async () => {
      //grab token balance of remaining tokens (of survey 1)
      const s1 = await survana.surveys(0)
      const s = await Survey.at(s1)
      const oldPool = await s.pool()
      const oldBal = await token.balanceOf(s1)

      const result = await survana.withdrawFromTokenPool(0, oldBal, {from: creator})
      let event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)
      assert.equal(event._amount.toString(), oldPool.tokenAmount.toString())

      const newPool = await s.pool()
      const newBal = await token.balanceOf(s1)

      assert.isAbove(+fromWei(oldBal), +fromWei(newBal))
      assert.isAbove(+fromWei(oldPool.tokenAmount), +fromWei(newPool.tokenAmount))
    })

    it("Should let the creator to withdraw the remaing gas from the pool", async () => {
      //grab token balance of remaining tokens (of survey 1)
      const s1 = await survana.surveys(0)
      const s = await Survey.at(s1)
      const oldBal = await s.getBalance()

      const result = await survana.withdrawFromGasPool(0, oldBal, {from: creator})
      let event = result.logs[0].args
      assert.equal(event._creator, creator)
      assert.equal(event._surveyId, 0)
      assert.equal(event._amount.toString(), oldBal.toString())

      const newBal = await s.getBalance()

      assert.isAbove(+fromWei(oldBal), +fromWei(newBal))
    })
  })

  //do withdraw last in this group
})
