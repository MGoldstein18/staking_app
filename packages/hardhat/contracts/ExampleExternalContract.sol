// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ExampleExternalContract {

  bool public completed;

  mapping (address => uint256) public addressToAmount;

  function complete() public payable {
    completed = true;
    addressToAmount[msg.sender] = msg.value;
  }

  function returnFunds() public {
    require(addressToAmount[msg.sender] > 0, "You aren't authorized to return funds");
     uint256 contractBalance = addressToAmount[msg.sender];
     addressToAmount[msg.sender] = 0;
     (bool sent, bytes memory data) = msg.sender.call{value: contractBalance}("");
     require(sent, "Return failed");
     completed = false;
  }
}
