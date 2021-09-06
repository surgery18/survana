// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

import "./SurveyInterface.sol";
import "./Token.sol";

contract Survey is SurveyInterface {

  //multichoice would store index, rating would be a number, and text is text
  // Question[] public questions;
  mapping(uint => Question) public questions;
  uint public questionCount = 0;

  mapping (uint => string[]) public answers;
  mapping (address => uint) private userAnswers;

  SurveyBuild public build;

  event SurveyStatusChanged(
    Status _status
  );
  
  constructor(address _creator, string memory _name, string memory _description, uint _bonusAmount) {

    build.info.name = _name;
    build.info.description = _description;
    build.info.bonusAmount = _bonusAmount;
    build.creator = _creator;
  }

  modifier isCreator {
    // require(build.creator == msg.sender);
    //if either one is the creator continue on
    require(build.creator == tx.origin, "Must be the creator to access this function"); 
    _;
  }

  function setSurveyStatus(Status _status) external isCreator {
    build.status = _status;
  }

  event Log(string s);

  function submitSurvey(
    uint _gas,
    Token _token,
    string[] calldata _answers
  ) external returns (uint) {
    require(_answers.length == questionCount, "Answer string array does not match the length of questions");
    //make sure we haven't done this survey before
    require(!didUserTakeSurvey(tx.origin), "Already took the survey");

    //make sure the creator didn't submit their own survey
    require(build.creator != tx.origin, "Creator cannot take the survey");
    //make sure it is still open
    require(build.status == Status.OPEN, "Survey is not open");
    //this calulates how much rewards they get
    uint reward = 0;
    uint8 filled = 0;
    for (uint i = 0; i < questionCount; i++) {
      Question memory q = questions[i];
      string memory a = _answers[i];
      if (bytes(a).length > 0) {
        reward += q.worth;
        filled++;
      } else if (q.required) {
        revert("Required question not filled out");
      }
    }
    if (filled == questionCount) {
      reward += build.info.bonusAmount;
    }
    //liquidity pool must have enough funds to continue this function
    require(reward <= build.pool.tokenAmount, "Not enough reward to give, cancelling submission.");

    userAnswers[tx.origin] = build.surveysTaken + 1; //tells you which id you are in the string[] of questions
    //push answers to mapping
    for(uint i = 0; i < _answers.length; i++) {
      string memory a = _answers[i];
      if (bytes(a).length > 0) {
        answers[i].push(a); 
      }
    }

    //this takes the money from the liquidity pool and sends them tokens
    _token.transfer(tx.origin, reward);
    build.pool.tokenAmount -= reward;
    build.pool.totalTokensSent += reward;

    //try to send them back the gas money
    if (build.pool.gasAmount > 0) {
      uint diff = build.pool.gasAmount - _gas;
      uint send = _gas;
      if (diff <= 0) {
        send = build.pool.gasAmount;
      }
      if (address(this).balance >= send) {
        address payable pa = payable(tx.origin);
        pa.transfer(send);
        build.pool.gasAmount -= send;
        build.pool.totalGasSent += send;
      }
    }

    //increment taken surveys
    build.surveysTaken++;

    //this checks to see if the survey needs to close
    //to check this we see if they can fund another survey
    if (build.pool.tokenAmount < worth()) {
      build.status = Status.FINISHED;
      emit SurveyStatusChanged(build.status);
    }
    return reward;
  }

  //find a way to eliminate these functions
  ////////////////////////////////////////////////////////////////
  function name() view external returns (string memory) {
    return build.info.name;
  }

  // function description() view external returns (string memory) {
  //   return build.info.description;
  // }

  function bonusAmount() view external returns (uint) {
    return build.info.bonusAmount;
  }

  function creator() view external returns (address) {
    return build.creator;
  }

  function status() view external returns (Status) {
    return build.status;
  }

  function info() view external returns (SurveyBasic memory) {
    return build.info;
  }

  function pool() view external returns (LiquidityPool memory) {
    return build.pool;
  }
  ////////////////////////////////////////////////////////////////

  function getBalance() view external returns (uint) {
    return address(this).balance;
  }

  function getOverview() view external returns (SurveyOverview memory) {
    return SurveyOverview({
      id: 0,
      addr: address(this),
      worth: worth(),
      bonusAmount: build.info.bonusAmount,
      name: build.info.name,
      description: build.info.description,
      status: build.status,
      taken: build.surveysTaken,
      gasLeft: build.pool.gasAmount,
      tokensLeft: build.pool.tokenAmount,
      questionCount: questionCount
    });
  }

  function worth() view public returns (uint) {
    uint w = 0;
    for (uint i = 0; i < questionCount; i++) {
      Question memory q = questions[i];
      w += q.worth;
    }
    return w;
  }

  function getQuestions() external view returns (Question[] memory) {
    Question[] memory q = new Question[](questionCount);
    for (uint256 index = 0; index < questionCount; index++) {
      q[index] = questions[index];
    }
    return q;
  }

  // function getUserAnswers() external view returns (string[] memory) {
  //   uint index = userAnswers[tx.origin] - 1;
  //   require(index >= 0, "No answers found");
  //   string[] memory ret = new string[](questionCount);
  //   for (uint256 i = 0; i < questionCount; i++) {
  //     ret[i] = answers[i][index];
  //   }
  //   return ret;
  // }

  function updateSurvey(
    string memory _name,
    string memory _description,
    uint _bonusAmount
  ) public isCreator {
    require(build.status == Status.NOT_OPENED, "Survey must be in editing stage");
    build.info.name = _name;
    build.info.description = _description;
    build.info.bonusAmount = _bonusAmount;
  }

  function addQuestion(
    QuestionType _qtypes,
    uint _worth,
    bool _required,
    string memory _title,
    string memory _qdescription,
    string[] memory _choices
  ) public  isCreator returns (uint) {
    require(build.status == Status.NOT_OPENED, "Survey must be in editing stage");
    updateQuestion(
      questionCount,
      _qtypes,
      _worth,
      _required,
      _title,
      _qdescription,
      _choices
    );
    questionCount++;

    return questionCount - 1;
  }

  function updateQuestion(
    uint _id,
    QuestionType _qtypes,
    uint _worth,
    bool _required,
    string memory _title,
    string memory _qdescription,
    string[] memory _choices
  ) public isCreator {
    require(build.status == Status.NOT_OPENED, "Survey must be in editing stage");
    questions[_id] = Question(
      _qtypes,
      _worth,
      _required,
      _title,
      _qdescription,
      _choices
    );
  }

  function depositToSurveyTokenPool(Token _token, uint _amount) external isCreator {
    require(_amount > 0, "amount has to be greater than zero");
    _token.transferFrom(tx.origin, address(this), _amount);
    build.pool.tokenAmount += _amount;
  }

  function depositToSurveyGasPool() external payable isCreator {
    require(msg.value > 0, "amount has to be greater than zero");
    build.pool.gasAmount += msg.value;
  }

  function withdrawFromTokenPool(Token _token, uint _amount) external isCreator {
    require(_amount > 0, "amount has to be greater than zero");
    require(_token.balanceOf(address(this)) >= _amount, "Balance has to be >= than the amount to withdraw");
    _token.transfer(tx.origin, _amount);
    build.pool.tokenAmount -= _amount;
  }

  function withdrawFromGasPool(uint _amount) external isCreator {
    require(_amount > 0, "amount has to be greater than zero");
    require(address(this).balance >= _amount, "Balance has to be >= than the amount to withdraw");
    address payable _addr = payable(tx.origin);
    _addr.transfer(_amount);
    build.pool.gasAmount -= _amount;
  }

  function didUserTakeSurvey(address _addr) view public returns (bool) {
    uint index = userAnswers[_addr];
    if (index > 0) {
      return true;
    }
    return false;
  }
}
