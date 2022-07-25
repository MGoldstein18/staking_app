// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;
  mapping (address => uint256) public depositTimestamps;

  uint256 public constant rewardRatePerBlock = 0.01 ether;
  uint256 public withdrawalDeadline = block.timestamp + 120 seconds;
  uint256 public claimDeadline = block.timestamp + 240 seconds;
  uint public currentBlock = 0;

  event Stake(address indexed sender, uint256 amount);
  event Received(address, uint);
  event Execute(address indexed sender, uint256 amouny);

  modifier withdrawalDeadlineReached (bool requireReached) {
    uint256 timeRemaining = withdrawalTimeLeft();
    if(requireReached) {
      require(timeRemaining == 0, "Withdrawal period has not been reached");
    } else {
      require(timeRemaining > 0, "Withdrawal perdiod has been reached");
    }
    _;
  }

  modifier claimDeadlineReached (bool claimReached) {
    uint256 timeRemaining = claimPeriodLeft();
    if(claimReached) {
      require(timeRemaining == 0, "Claim deadline has not yet been reached");
    } else {
      require(timeRemaining > 0, "Claim deadline has been reached");
    }
    _;
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function withdrawalTimeLeft() public view returns (uint256 withdrawalTimeLeft) {
    if(block.timestamp >= withdrawalDeadline) {
      return (0);
    } else {
      return (withdrawalDeadline - block.timestamp);
    }
  }

  function claimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
    if(block.timestamp >= claimDeadline) {
      return (0);
    } else {
      return (claimDeadline - block.timestamp);
    }
  }

  function stake() public payable withdrawalDeadlineReached(false) claimDeadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted {
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    // add a mutiplier to reward length of time staked
    uint256 multiplier = (block.timestamp - depositTimestamps[msg.sender]) / 24;
    uint256 individualBalanceRewards = individualBalance + ((block.timestamp - depositTimestamps[msg.sender]) * rewardRatePerBlock * multiplier);
    balances[msg.sender] = 0;

    (bool sent, bytes memory data) = msg.sender.call{value: individualBalanceRewards}("");
    require(sent, "RIP; withdrawal failed");
  }

  function execute() public claimDeadlineReached(true) notCompleted {
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: contractBalance}();
  }

  function killTime() public {
    currentBlock = block.timestamp;
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function retrieveFunds() public {
    exampleExternalContract.returnFunds();
  }

}
