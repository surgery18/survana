// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

contract SurveyInterface {
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

  struct LiquidityPool {
    uint tokenAmount;
    uint gasAmount;
    uint totalGasSent;
    uint totalTokensSent;
  }

  struct SurveyBasic {
    string name;
    string description;
    // uint worth;
    uint bonusAmount;
  }

  struct SurveyBuild {
    SurveyBasic info;
    // Question[] questions;
    LiquidityPool pool;
    uint surveysTaken;
    Status status;
    address creator;
  }
}