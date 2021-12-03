pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    YourToken yourToken;

    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfEth, uint256 amountOfTokens);
    event SellTokens(
        address seller,
        uint256 amountOfEth,
        uint256 amountOfTokens
    );

    constructor(address tokenAddress) public {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        require(msg.value > 0, "Need to send ETH to buy tokens");

        uint256 vendorTokenBalance = yourToken.balanceOf(address(this));
        uint256 tokensToBuy = msg.value * tokensPerEth;

        require(
            vendorTokenBalance >= tokensToBuy,
            "Vendor doesn't have enough tokens to sell"
        );
        bool sent = yourToken.transfer(msg.sender, tokensToBuy);
        require(sent, "Failed to transfer tokens from Vendor to buyer");

        emit BuyTokens(msg.sender, msg.value, tokensToBuy);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public payable onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Owner failed to withdraw ETH from Vendor");
    }

    // ToDo: create a sellTokens() function:
    function sellTokens(uint256 tokensToSell) public payable {
        require(
            yourToken.balanceOf(msg.sender) >= tokensToSell,
            "User doesn't have enough tokens to sell"
        );

        uint256 amountOfEthToReturn = tokensToSell / tokensPerEth;

        require(
            address(this).balance >= amountOfEthToReturn,
            "Vendor doesn't have enough ETH to buy back tokens"
        );

        bool sent = yourToken.transferFrom(
            msg.sender,
            address(this),
            tokensToSell
        );
        require(sent, "Failed to transfer tokens from seller to vendor");

        (sent, ) = msg.sender.call{value: amountOfEthToReturn}("");
        require(sent, "Failed to send ETH to user");

        emit SellTokens(msg.sender, amountOfEthToReturn, tokensToSell);
    }
}
