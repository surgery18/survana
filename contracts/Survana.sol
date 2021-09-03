// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
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
import "./Ownable.sol";
import "./Token.sol";
import "./SurveyInterface.sol";

contract Survana is Ownable, SurveyInterface {
  string public name = "Survana";
  mapping (address => bool) creators;
  Token public token;
  mapping (uint => address) public surveys;
  uint surveyCount = 0;

  //TODO
  //UNIT TESTS

  constructor(Token _token) public {
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
    require(_amount > 0);
    Survey s = Survey(surveys[_id]);
    require(bytes(s.name()).length > 0);
    s.depositToSurveyTokenPool(token, _amount);
    emit DepositedTokensToPool(msg.sender, _id, _amount);
  }

  function depositToSurveyGasPool(uint _id) external isCreator payable {
    require(msg.value > 0);
    Survey s = Survey(surveys[_id]);
    address payable _survContract = address(uint256(surveys[_id]));
    _survContract.transfer(msg.value);
    s.depositToSurveyGasPool(msg.value);
    emit DepositedGasToPool(msg.sender, _id, msg.value);
  }

  function withdrawFromTokenPool(uint _id, uint _amount) external isCreator {
    require(_amount > 0);
    Survey s = Survey(surveys[_id]);
    s.withdrawFromTokenPool(token, _amount);
    emit WithdrawFromTokenPool(msg.sender, _id, _amount);
  }

  function withdrawFromGasPool(uint _id, uint _amount) external isCreator {
    require(_amount > 0);
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
    emit SurveyCreated(msg.sender, newContract, surveyCount);
    surveyCount++;
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
    s.setSurveyStatus(_status);
    emit SurveyStatusChanged(_status, _id);
  }


  function submitSurvey(
    uint _id,
    string[] calldata _answers
  ) external {
    uint gas = gasleft();
    Survey s = Survey(surveys[_id]);
    uint reward = s.submitSurvey(gas, token, _answers);
    emit SurveySubmited(msg.sender, _id, reward);
  }

  function getCreatorSurveys() external view returns (Survey[] memory) {
    require(creators[msg.sender] == true);
    Survey[] memory _tmp;
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      if (s.creator() == msg.sender) {
        _tmp[count] = s;
        count++;
      }
    }
    return _tmp;
  }

  function getOpenSurveys() external view returns (Survey[] memory) {
    Survey[] memory _tmp;
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      if (s.status() == Status.OPEN && s.creator() != msg.sender) {
        _tmp[count] = s;
        count++;
      }
    }
    return _tmp;
  }

  function getUserFinishedSurveys() external view returns (Survey[] memory) {
    Survey[] memory _tmp;
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      if (s.status() == Status.FINISHED && s.didUserTakeSurvey(msg.sender)) {
        _tmp[count] = s;
        count++;
      }
    }
    return _tmp;
  }

  function setToken(Token _token) external onlyOwner {
    token = _token;
    emit TokenChanged(_token);
  }
}
