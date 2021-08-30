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

import "./Ownable.sol";
import "./Survey.sol";

contract Survana is Ownable, Survey {
  string public name = "Survana";
  mapping (address => bool) creators;
  
  modifier isCreator() {
    require(creators[msg.sender] == true);
    _;
  }

  function addCreator(address _addr) external onlyOwner {
    creators[_addr] = true;
  }

  function removeCreator(address _addr) external onlyOwner {
    creators[_addr] = false;
  }
}
