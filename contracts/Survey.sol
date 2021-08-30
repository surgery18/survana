// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Survey {
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
    uint choicesCount;
    string[] answers; //multichoice would store index, rating would be a number, and text is text
    mapping (address => string) userAnswer;
    uint answerCount;
  }

  struct SurveyBuild {
    Question[] questions;
    uint count;
    uint bonusAmount; //for completing the survey
    uint tokenPoolAmount;
    address creator;
  }

  mapping (uint => SurveyBuild) public survey;
  uint surveyCount;


  //functions todo
  /*
    
  */
}
