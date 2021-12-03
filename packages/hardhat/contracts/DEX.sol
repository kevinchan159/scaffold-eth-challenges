pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    using SafeMath for uint256;

    IERC20 token;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    // write your functions here...
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX:init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens));
        return totalLiquidity;
    }

    function price(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount.mul(997);
        uint256 numerator = inputAmountWithFee.mul(outputReserve);
        uint256 denominator = inputReserve.mul(1000).add(inputAmountWithFee);
        return numerator / denominator;
    }

    function ethToToken() public payable returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokensBought = price(
            msg.value,
            address(this).balance.sub(msg.value),
            tokenReserve
        );
        require(token.transfer(msg.sender, tokensBought));
        return tokensBought;
    }

    function tokenToEth(uint256 tokens) public returns (uint256) {
        uint256 ethReserve = address(this).balance;
        uint256 ethBought = price(
            tokens,
            token.balanceOf(address(this)),
            ethReserve
        );

        (bool sent, ) = msg.sender.call{value: ethBought}("");
        require(sent, "Failed to send the user ETH");

        require(token.transferFrom(msg.sender, address(this), tokens));

        return ethBought;
    }

    function deposit() public payable returns (uint256) {
        uint256 ethReserve = address(this).balance.sub(msg.value);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenAmount = ((msg.value * tokenReserve) / ethReserve).add(1);

        uint256 liquidityMinted = (msg.value * totalLiquidity) / ethReserve;
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidityMinted);
        totalLiquidity = totalLiquidity.add(liquidityMinted);

        require(token.transferFrom(msg.sender, address(this), tokenAmount));

        return liquidityMinted;
    }

    function withdraw(uint256 amount) public returns (uint256, uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethAmount = amount.mul(address(this).balance) / totalLiquidity;
        uint256 tokenAmount = amount.mul(tokenReserve) / totalLiquidity;

        liquidity[msg.sender] = liquidity[msg.sender].sub(ethAmount);
        totalLiquidity = totalLiquidity.sub(ethAmount);

        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "Failed to send the user ETH");

        require(token.transfer(msg.sender, tokenAmount));

        return (ethAmount, tokenAmount);
    }
}
