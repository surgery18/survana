// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/*
Survana
----------------------
1. A owner can add a creator to add survies
2. A creator can create a survey that has unlimited questions.
3. A question can be one of the following types of questions
	- A mulitple choice
	- Text
	- Rate
4. Each question will be assigned an amount of tokens that can be earned for completed it
5. They can mark a question as required or optional (defaulted)
6. The creator has to fill the liquidity pool for that survey with tokens to be distrubted to people
7. There can be an extra bonus for completing the whole survey (which the creator can define how much that is)
8. The creator can stop the survey at anytime. (will stop clients who are on it currently).
9. Once the contract determines the survey cannot fulfill another disbrusment of funds, it will auto close it. (will stop clients)
10. A client can only do a survey once
11. When survey has started, the questions cannot be changed.
*/

import "./Survey.sol";
import "../../swap-thang/contracts/Token.sol";

contract Survana is Survey {
  string public name = "Survana";
  mapping (address => bool) creators;
  Token public token;

  //TODO
  //UNIT TESTS

  constructor(Token memory _token) public {
    token = _token;
  }
  
  modifier isCreator() {
    require(creators[msg.sender] == true);
    _;
  }


  event AddedCreator(
    address indexed _creator
  );

  event RemovedCreator(
    address indexed _creator
  );

  event DepositedTokensToPool(
    address _creator,
    uint _surveyId,
    uint _amount,
    uint _totalInSurveyPool
  );

  event SurveyCreated(
    address indexed _creator,
    uint _surveyId
  );

  event SurveyUpdated(
    address indexed _creator,
    uint _surveyId
  );

  event SurveySubmited(
    address indexed _user,
    uint _surveyId,
    uint _tokensAwarded
  );

  event TokenChanged(
    Token _token
  );

  function addCreator(address _addr) external onlyOwner {
    creators[_addr] = true;
    emit AddedCreator(_addr);
  }

  function removeCreator(address _addr) external onlyOwner {
    creators[_addr] = false;
    emit RemovedCreator(_addr);
  }

  function depositToSurveyTokenPool(uint _id, uint _amount) external isCreator {
    //check if it exists
    SurveyBuild storage s = surveys[_id];
    require(bytes(s.name).length > 0);
    //grab the tokens from the user
    //MAKE SURE TO CALL APPROVE FIRST
    token.transferFrom(msg.sender, address(this), _amount);
    // token.transfer(address(this), _amount);
    s.tokenPoolAmount += _amount;
    emit DepositedTokensToPool(msg.sender, _id, _amount, s.tokenPoolAmount);
  }


  function createSurvey(SurveyBuild storage _build) external isCreator {
    require(creators[msg.sender] == true);
    _build.creator = msg.sender;
    _build.status = Status.NOT_OPENED;
    _build.tokenPoolAmount = 0;
    uint worth = 0;
    for (uint i = 0; i < _build.questions.length; i++) {
      Question memory q = _build.questions[i];
      worth += q.worth;
    }
    _build.questionsWorth = worth;
    surveys[surveyCount] = _build;
    emit SurveyCreated(msg.sender, surveyCount);
    surveyCount++;
  }

  function updateSurvey(uint _id, SurveyBuild storage _build) external isCreator {
    require(creators[msg.sender] == true);
    require(surveys[_id].status == Status.NOT_OPENED);
    uint worth = 0;
    for (uint i = 0; i < _build.questions.length; i++) {
      Question memory q = _build.questions[i];
      worth += q.worth;
    }
    _build.questionsWorth = worth;
    surveys[_id] = _build;
    emit SurveyUpdated(msg.sender, _id);
  }

  function submitSurvey(uint _id, SurveyAnswers memory _answers) external {
    //grab the survey data
    SurveyBuild storage s = surveys[_id];
    //make sure it is still open
    require(s.status == Status.OPEN);
    //make sure the creator didn't submit their own survey
    require(s.creator != msg.sender);
    //this calulates how much rewards they get
    uint reward = 0;
    uint8 filled = 0;
    for (uint j = 0; j < s.questions.length; j++) {
      Question memory q = s.questions[j];
      string memory a = _answers.answers[i];
      if (bytes(a).length > 0) {
        reward += q.worth;
        filled++;
      }
    }
    if (filled == s.questions.length) {
      reward += s.bonusAmount;
    }
    //liquidity pool must have enough funds to continue this function
    require(reward <= s.tokenPoolAmount);

    //make sure we haven't done this survey before
    require(userAnswers[msg.sender][_id] == 0);
    //user submits their answers
    userAnswers[msg.sender][_id] = _answers;
    //push answers to mapping
    for(uint i = 0; i < _answers.answers.length; i++) {
      string memory a = _answers.answers[i];
      if (bytes(a).length > 0) {
        answers[_id][i].push(a); 
      }
    }
    //this takes the money from the liquidity pool and sends them tokens
    token.transfer(msg.sender, reward);
    s.tokenPoolAmount -= reward;

    //this checks to see if the survey needs to close
    //to check this we see if they can fund another survey
    if (s.tokenPoolAmount < s.questionsWorth) {
      s.status = Status.FINISHED;
      emit SurveyStatusChanged(_id, s.status);
    }

    emit SurveySubmited(msg.sender, _id, reward);
  }

  function getCreatorSurveys() external view returns (SurveyBasic[] memory) {
    require(creators[msg.sender] == true);
    SurveyBasic[] memory _tmp;
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      SurveyBuild memory s = surveys[index];
      if (s.creator == msg.sender) {
        _tmp[count] = (SurveyBasic(s.name, s.description, s.questionsWorth, s.bonusAmount));
        count++;
      }
    }
    return _tmp;
  }

  function setToken(Token memory _token) external onlyOwner {
    token = _token;
    emit TokenChanged(_token);
  }
}
