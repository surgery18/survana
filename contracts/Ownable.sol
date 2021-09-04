// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract Ownable {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    _setOwner(_newOwner);
  }

  function renounceOwnership() public onlyOwner {
    _setOwner(address(0));
  }

  function _setOwner(address _newOwner) private {
    address oldOwner = owner;
    owner = _newOwner;
    emit OwnershipTransferred(oldOwner, _newOwner);
  }

  modifier onlyOwner {
    require(isOwner());
    _;
  }

  function isOwner() public view returns (bool){
    return msg.sender == owner;
  }
}
