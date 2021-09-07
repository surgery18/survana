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

  //TODO store totalTokensRewards by address sp we cam show it on the site
  //Refactor contracts
  //add selfdestruct to survey (a way to delete surveys they accidently made)
  //more?

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

  function addCreator(address _addr) external {
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
    s.depositToSurveyGasPool{value: msg.value}();
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

  function _getSurveyOverviews(uint arrayCount, bool openAndNotCreator, bool userFinished, bool isCreators) private view returns (SurveyOverview[] memory) {
    SurveyOverview[] memory _tmp = new SurveyOverview[](arrayCount);
    // require(_tmp.length == 0, "LENGTH IS MORE THAN 0");
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      Survey s = Survey(surveys[index]);
      bool check1 = !openAndNotCreator || (openAndNotCreator && s.status() == Status.OPEN && s.creator() != msg.sender && !s.didUserTakeSurvey(msg.sender));
      bool check2 = !userFinished || (userFinished && s.didUserTakeSurvey(msg.sender));
      bool check3 = !isCreators || (isCreators && s.creator() == msg.sender);
      if (check1 && check2 && check3) {
        SurveyOverview memory so = s.getOverview();
        so.id = index;
        _tmp[count] = so;
        count++;
      }
    }
    if (_tmp.length > count) {
      //re-copy over everything to remove blank enties
      SurveyOverview[] memory ret = new SurveyOverview[](count);
      for (uint256 index = 0; index < count; index++) {
        ret[index] = _tmp[index];
      }
      return ret;
    }
    return _tmp;
  }

  function getCreatorSurveys() external view returns (SurveyOverview[] memory) {
    return _getSurveyOverviews(creatorSurveyCount[msg.sender], false, false, true);
  }

  function getOpenSurveys() external view returns (SurveyOverview[] memory) {
    return _getSurveyOverviews(statusCounts[Status.OPEN], true, false, false);
  }

  function getUserFinishedSurveys() external view returns (SurveyOverview[] memory) {
    return _getSurveyOverviews(surveyCount, false, true, false);
  }

  function setToken(Token _token) external onlyOwner {
    token = _token;
  }
}
