pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    YourToken yourToken;

    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfEth, uint256 amountOfTokens);

    constructor(address tokenAddress) public {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        uint256 tokens = msg.value * tokensPerEth;
        yourToken.transfer(msg.sender, tokens);
        emit BuyTokens(msg.sender, msg.value, tokens);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public payable onlyOwner {
        yourToken.transfer(owner(), msg.value * tokensPerEth);
    }

    // ToDo: create a sellTokens() function:
}
