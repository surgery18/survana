// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

import "./Ownable.sol";
import "./SurveyInterface.sol";
import "./Token.sol";

contract Survey is SurveyInterface {

  //multichoice would store index, rating would be a number, and text is text
  // Question[] public questions;
  mapping(uint => Question) public questions;
  uint questionCount = 0;

  mapping (uint => string[]) internal answers;
  mapping (address => uint) internal userAnswers;

  SurveyBuild public build;

  event SurveyStatusChanged(
    Status _status
  );

  // constructor(SurveyBuild memory _b, Question[] memory _q) public {
  //   build = _b;
  //   for (uint i = 0; i < _q.length; i++) {
  //     questions[i] = _q[i];
  //   }
  // }
  
  constructor(address _creator, string memory _name, string memory _description, uint _bonusAmount) {
    // build = _b;
    // for (uint i = 0; i < _q.length; i++) {
    //   questions[i] = _q[i];
    // }
    build.info.name = _name;
    build.info.description = _description;
    build.info.bonusAmount = _bonusAmount;
    build.creator = _creator;
  }

  modifier isCreator {
    // require(build.creator == msg.sender);
    //if either one is the creator continue on
    require(build.creator == tx.origin); 
    _;
  }

  function setSurveyStatus(Status _status) external isCreator {
    build.status = _status;
  }

  function submitSurvey(
    uint _gas,
    Token _token,
    string[] calldata _answers
  ) external returns (uint) {
    //make sure the creator didn't submit their own survey
    //require(build.creator != msg.sender);
    require(build.creator != tx.origin);
    //make sure it is still open
    require(build.status == Status.OPEN);
    //this calulates how much rewards they get
    uint reward = 0;
    uint8 filled = 0;
    for (uint i = 0; i < questionCount; i++) {
      Question memory q = questions[i];
      string memory a = _answers[i];
      if (bytes(a).length > 0) {
        reward += q.worth;
        filled++;
      }
    }
    if (filled == questionCount) {
      reward += build.info.bonusAmount;
    }
    //liquidity pool must have enough funds to continue this function
    require(reward <= build.pool.tokenAmount);

    //make sure we haven't done this survey before
    // require(userAnswers[msg.sender][_id].answers.length == 0);
    require(!didUserTakeSurvey(tx.origin));
    //user submits their answers
    // userAnswers[msg.sender][_id] = SurveyAnswers(_answers);
    // string[] memory copyAnswers;
    // for (uint i = 0; i < _answers.length; i++) {
    //   copyAnswers[i] = _answers[i];
    // }
    userAnswers[msg.sender] = build.surveysTaken;
    //push answers to mapping
    for(uint i = 0; i < _answers.length; i++) {
      string memory a = _answers[i];
      if (bytes(a).length > 0) {
        answers[i].push(a); 
      }
    }
    //this takes the money from the liquidity pool and sends them tokens
    _token.transfer(msg.sender, reward);
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
        address payable pa = payable(msg.sender);
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

  function name() view external returns (string memory) {
    return build.info.name;
  }

  function description() view external returns (string memory) {
    return build.info.description;
  }

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

  function worth() view public returns (uint) {
    uint w = 0;
    for (uint i = 0; i < questionCount; i++) {
      Question memory q = questions[i];
      w += q.worth;
    }
    return w;
  }

  function updateSurvey(
    string memory _name,
    string memory _description,
    uint _bonusAmount
  ) public isCreator {
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
    require(_amount > 0);
    _token.transferFrom(msg.sender, address(this), _amount);
    build.pool.tokenAmount += _amount;
  }

  function depositToSurveyGasPool(uint _value) external isCreator {
    require(_value > 0);
    build.pool.gasAmount += _value;
  }

  function withdrawFromTokenPool(Token _token, uint _amount) external isCreator {
    require(_amount > 0);
    require(_token.balanceOf(address(this)) >= _amount);
    _token.transfer(msg.sender, _amount);
    build.pool.tokenAmount -= _amount;
  }

  function withdrawFromGasPool(uint _amount) external isCreator {
    require(_amount > 0);
    require(address(this).balance >= _amount);
    address payable _addr = payable(msg.sender);
    _addr.transfer(_amount);
    build.pool.gasAmount -= _amount;
  }

  function didUserTakeSurvey(address _addr) view public returns (bool) {
    uint index = userAnswers[_addr];
    for (uint i = 0; i < questionCount; i++) {
      string memory a = answers[i][index];
      if (bytes(a).length > 0) {
        return true;
      }
    }
    return false;
  }
}
