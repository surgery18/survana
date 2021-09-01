// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";

contract Survey is Ownable {
  enum Status {
    NOT_OPENED,
    OPEN,
    FINISHED
  }

  enum QuestionType {
    MULTIPLE_CHOICE,
    RATE,
    TEXT
  }

  struct Question {
    QuestionType questionType;
    uint worth;
    bool required;
    string title;
    string description;
    string[] choices;
  }

  struct SurveyBuild {
    string name;
    string description;
    Question[] questions;
    uint bonusAmount;
    uint tokenPoolAmount;
    uint questionsWorth;
    Status status;
    address creator;
  }

  struct SurveyBasic {
    string name;
    string description;
    uint worth;
    uint bonusAmount;
  }

  struct SurveyAnswers {
    string[] answers;
  }

  //multichoice would store index, rating would be a number, and text is text
  mapping (uint => mapping(uint => string[])) internal answers;
  mapping (address => SurveyAnswers[]) internal userAnswers;
  mapping (uint => SurveyBuild) internal surveys;
  uint surveyCount;

  event SurveyStatusChanged(
    uint _surveyId,
    Status _status
  );

  function setSurveyStatus(uint _id, Status _status) external {
    require(surveyCount >= _id);
    SurveyBuild storage surv = surveys[_id];
    require(surv.creator == msg.sender || surv.creator == owner);
    surv.status = _status;
    emit SurveyStatusChanged(_id, _status);
  }

  function getOpenSurveys() external view returns (SurveyBasic[] memory) {
    // SurveyBuild[] memory _tmp;
    SurveyBasic[] memory _tmp;
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      SurveyBuild memory s = surveys[index];
      if (s.status == Status.OPEN && s.creator != msg.sender) {
        _tmp[count] = (SurveyBasic(s.name, s.description, s.questionsWorth, s.bonusAmount));
        count++;
      }
    }
    return _tmp;
  }

  function getUserFinishedSurveys() external view returns (SurveyBasic[] memory) {
    SurveyAnswers[] memory ua = userAnswers[msg.sender];
    require(ua.length > 0);
    SurveyBasic[] memory _tmp;
    uint count = 0;
    for (uint256 index = 0; index < surveyCount; index++) {
      SurveyBuild memory s = surveys[index];
      if (s.status == Status.FINISHED) {
        SurveyAnswers memory _surv = ua[index];
        if (_surv.answers.length > 0) {
          _tmp[count] = (SurveyBasic(s.name, s.description, s.questionsWorth, s.bonusAmount));
          count++;
        }
      }
    }
    return _tmp;
  }

  function fetchSurveyDetails(uint _id) external view returns (SurveyBuild memory) {
    require(_id < surveyCount);
    require(bytes(surveys[_id].name).length > 0);
    return surveys[_id];
  }
}
