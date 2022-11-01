// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./baseContract.sol";

contract Dex is Helper {
    /* This contract has following functionalities
     1. Create new tokens
     2. Deposit/Withdraw Token 
     */

    constructor() {
        owner = msg.sender;
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

    mapping(address => mapping(bytes32 => uint256)) tradersBalances;

    // confusion
    function deposit(bytes32 ticker, uint256 amount)
        external
        isTokenExist(ticker)
    {
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
