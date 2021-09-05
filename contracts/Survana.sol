// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

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
import "./Ownable.sol";
import "./Token.sol";
import "./SurveyInterface.sol";

contract Survana is Ownable, SurveyInterface {
  string public name = "Survana";
  mapping (address => bool) public creators;
  Token public token;
  mapping (uint => address) public surveys;
  uint public surveyCount = 0;
  mapping (Status => uint) public statusCounts;

  mapping (address => uint) public creatorSurveyCount;

  constructor(Token _token) {
    token = _token;
  }


  modifier isCreator() {
    require(creators[msg.sender] == true, "Must be creator");
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
    uint _amount
  );

  event DepositedGasToPool(
    address _creator,
    uint _surveyId,
    uint _amount
  );

  event WithdrawFromTokenPool(
    address _creator,
    uint _surveyId,
    uint _amount
  );

  event WithdrawFromGasPool(
    address _creator,
    uint _surveyId,
    uint _amount
  );

  event SurveyCreated(
    address indexed _creator,
    address indexed _newContract,
    uint _surveyId
  );

  event SurveyUpdated(
    address indexed _creator,
    address indexed _contract,
    uint _surveyId
  );

  event SurveySubmited(
    address indexed _user,
    uint _surveyId,
    uint _tokensAwarded
  );

  event QuestionAdded(
    address indexed _creator,
    address indexed _contract,
    uint _surveyId,
    uint _questionId
  );

  event QuestionUpdated(
    address indexed _creator,
    address indexed _contract,
    uint _surveyId,
    uint _questionId
  );

  event SurveyStatusChanged(
    Status _status,
    uint _id
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
    require(_amount > 0, "amount has to be greater than zero");
    Survey s = Survey(surveys[_id]);
    require(bytes(s.name()).length > 0, "Length of string needs to be greater than zero");
    s.depositToSurveyTokenPool(token, _amount);
    emit DepositedTokensToPool(msg.sender, _id, _amount);
  }

  function depositToSurveyGasPool(uint _id) external payable isCreator {
    require(msg.value > 0, "Value needs to be > 0");
    Survey s = Survey(surveys[_id]);
    // address payable _addr = payable(address(s));
    // _addr.transfer(msg.value);
    // (bool sent, bytes memory data) = _addr.call{value: msg.value}("");
    // bool sent = _addr.send(msg.value);
    s.depositToSurveyGasPool{value: msg.value}();
    // require(sent, "Failed to send Ether");
    emit DepositedGasToPool(msg.sender, _id, msg.value);
  }

  function withdrawFromTokenPool(uint _id, uint _amount) external isCreator {
    require(_amount > 0, "amount has to be greater than zero");
    Survey s = Survey(surveys[_id]);
    s.withdrawFromTokenPool(token, _amount);
    emit WithdrawFromTokenPool(msg.sender, _id, _amount);
  }

  function withdrawFromGasPool(uint _id, uint _amount) external isCreator {
    require(_amount > 0, "amount has to be greater than zero");
    Survey s = Survey(surveys[_id]);
    s.withdrawFromGasPool(_amount);
    emit WithdrawFromGasPool(msg.sender, _id, _amount);
  }

  function createSurvey(
    string calldata _name,
    string calldata _description,
    uint _bonusAmount
  ) external isCreator {
    Survey s = new Survey(msg.sender, _name, _description, _bonusAmount);
    address newContract = address(s);
    surveys[surveyCount] = newContract;
    statusCounts[Status.NOT_OPENED]++;
    emit SurveyCreated(msg.sender, newContract, surveyCount);
    surveyCount++;
    creatorSurveyCount[msg.sender] = surveyCount;
  }

  function updateSurvey(
    uint _id,
    string calldata _name,
    string calldata _description,
    uint _bonusAmount
  ) external isCreator {
    Survey s = Survey(surveys[_id]);
    s.updateSurvey(_name, _description, _bonusAmount);
    emit SurveyUpdated(msg.sender, address(s), _id);
  }

  function addQuestion(
    uint _id,
    QuestionType _qtypes,
    uint _worth,
    bool _required,
    string memory _title,
    string memory _qdescription,
    string[] memory _choices
  ) public  isCreator {
    Survey s = Survey(surveys[_id]);
    uint qid = s.addQuestion(_qtypes, _worth, _required, _title, _qdescription, _choices);
    emit QuestionAdded(msg.sender, address(s), _id, qid);
  }

  function updateQuestion(
    uint _id,
    uint _qid,
    QuestionType _qtypes,
    uint _worth,
    bool _required,
    string memory _title,
    string memory _qdescription,
    string[] memory _choices
  ) public isCreator {
    Survey s = Survey(surveys[_id]);
    s.updateQuestion(_qid, _qtypes, _worth, _required, _title, _qdescription, _choices);
    emit QuestionUpdated(msg.sender, address(s), _id, _qid);
  }

  function setSurveyStatus(uint _id, Status _status) external isCreator {
    Survey s = Survey(surveys[_id]);
    Status old = s.status();
    s.setSurveyStatus(_status);
    statusCounts[old]--;
    statusCounts[_status]++;
    emit SurveyStatusChanged(_status, _id);
  }

  function submitSurvey(
    uint _id,
    string[] calldata _answers
  ) external {
    require(_id < surveyCount && _id >= 0, "ID must exist");
    uint gas = gasleft();
    Survey s = Survey(surveys[_id]);
    Status oldS = s.status();
    uint reward = s.submitSurvey(gas, token, _answers);
    Status newS = s.status();
    if (newS != oldS) {
      statusCounts[oldS]--;
      statusCounts[newS]++;
    }
    emit SurveySubmited(msg.sender, _id, reward);
  }

  function getCreatorSurveys() external view returns (SurveyBasic[] memory) {
    require(creators[msg.sender] == true);
    SurveyBasic[] memory _tmp = new SurveyBasic[](creatorSurveyCount[msg.sender]);
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      if (s.creator() == msg.sender) {
        _tmp[count] = s.info();
        count++;
      }
    }
    return _tmp;
  }

  function getOpenSurveys() external view returns (SurveyBasic[] memory) {
    SurveyBasic[] memory _tmp = new SurveyBasic[](statusCounts[Status.OPEN]);
    // require(_tmp.length == 0, "LENGTH IS MORE THAN 0");
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      if (s.status() == Status.OPEN && s.creator() != msg.sender) {
        _tmp[count] = s.info();
        count++;
      }
    }
    if (_tmp.length > count) {
      //re-copy over everything to remove blank enties
      SurveyBasic[] memory ret = new SurveyBasic[](count);
      for (uint256 index = 0; index < count; index++) {
        ret[index] = _tmp[index];
      }
      return ret;
    }
    return _tmp;
  }

  function getUserFinishedSurveys() external view returns (SurveyBasic[] memory) {
    SurveyBasic[] memory _tmp = new SurveyBasic[](surveyCount);
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      if (s.didUserTakeSurvey(msg.sender)) {
        _tmp[count] = s.info();
        count++;
      }
    }
    if (_tmp.length > count) {
      //re-copy over everything to remove blank enties
      SurveyBasic[] memory ret = new SurveyBasic[](count);
      for (uint256 index = 0; index < count; index++) {
        ret[index] = _tmp[index];
      }
      return ret;
    }
    return _tmp;
  }

  function setToken(Token _token) external onlyOwner {
    token = _token;
    emit TokenChanged(_token);
  }
}
