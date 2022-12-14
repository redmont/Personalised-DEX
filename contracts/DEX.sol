// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./baseContract.sol";
import "./Orders.sol";
import "./Traders.sol";

contract Dex is Helper, Traders, OrdersManagement {
    /* This contract has following functionalities
     1. Create new tokens
     2. Deposit/Withdraw Token 
     */

    constructor() {
        owner = msg.sender;
    }

    function getTokens() external view returns (token[] memory) {
        token[] memory _tokens = new token[](tokensList.length);
        for (uint256 i = 0; i < tokensList.length; i++) {
            _tokens[i] = token(
                tokens[tokensList[i]].ticker,
                tokens[tokensList[i]].tokenName,
                tokens[tokensList[i]].tokenAddress
            );
        }
        return _tokens;
    }

    function addNewToken(
        bytes32 ticker,
        string memory tokenName,
        address tokenAddress
    ) external isTickerAvailable(ticker) isOwner {
        token memory newToken = token(ticker, tokenName, tokenAddress);
        tokens[ticker] = newToken;
        tokensList.push(ticker);
    }

    // confusion
    function deposit(bytes32 ticker, uint256 amount)
        external
        isTokenExist(ticker)
    {
        // this is using interface to call transferFrom func of token contract
        IERC20(tokens[ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        // record transaction in DEX ledger
        tradersBalances[msg.sender][ticker] += amount;
    }

    function withdraw(bytes32 ticker, uint256 amount)
        external
        isTokenExist(ticker)
    {
        require(
            tradersBalances[msg.sender][ticker] >= amount,
            "Insufficient balance"
        );

        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);

        // record transaction in DEX ledger
        tradersBalances[msg.sender][ticker] -= amount;
    }
}
