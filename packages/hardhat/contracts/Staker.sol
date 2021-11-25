pragma solidity 0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    using SafeMath for uint256;

    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 30 seconds;

    event Stake(address indexed _address, uint256 _amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        require(msg.sender != address(0));

        balances[msg.sender] = balances[msg.sender].add(msg.value);

        emit Stake(msg.sender, msg.value);
    }

    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Already staked");
        _;
    }

    modifier deadlineReached(bool _requireReached) {
        uint256 timeRemaining = timeLeft();
        if (_requireReached) {
            require(timeRemaining == 0, "Time not reached yet");
        } else {
            require(timeRemaining > 0, "Time reached already");
        }
        _;
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public deadlineReached(true) stakeNotCompleted {
        uint256 contractBalance = address(this).balance;

        require(contractBalance >= threshold, "Not enough contract balance");

        exampleExternalContract.complete{value: contractBalance}();
    }

    // // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw() public deadlineReached(true) stakeNotCompleted {
        uint256 userBalance = balances[msg.sender];

        // check if the user has balance to withdraw
        require(userBalance > 0, "You don't have balance to withdraw");

        // reset the balance of the user
        balances[msg.sender] = 0;

        // Transfer balance back to the user
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send user balance back to the user");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake().
    // This makes sure if you send ETH directly to the contract address (w/o calling
    // stake), it updates the balance as well.
    receive() external payable {
        stake();
    }
}
