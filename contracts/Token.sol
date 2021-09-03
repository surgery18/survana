// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

contract Token {
    string public name = "Pango Token";
    string public symbol = "PANGO";
    uint256 public totalSupply =  1 * (10**9) * (10**18); //1 Billion
    uint8 public decimals = 18;

    constructor() public {
        balance[msg.sender] = totalSupply;
    }

    mapping (address => uint256) balance;
    mapping (address => mapping(address => uint256)) allowance;

    //events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //functions
    function balanceOf(address _addr) public view returns (uint256) {
        return balance[_addr];
    }

    function allowanceOf(address _from, address _addr) external view returns (uint256) {
        return allowance[_from][_addr];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        //move your funds to another account
        require(balance[msg.sender] >= _value, "Not enough tokens");
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        //sender must be allowed to take funds from account A
        //first of all from address must be allowed to move it to account B
        require(balance[_from] >= _value, "Not enough tokens");
        require(allowance[_from][msg.sender] >= _value, "Sender is not allowed to move funds.");
        //change balances
        balance[_from] -= _value;
        balance[_to] += _value;
        //remove it from the allowance
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(balance[msg.sender] >= _value, "Not enough tokens");
        //attach spender address to sender
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}