// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    /* This contract has following functionalities
     1. Create new tokens
     2. Deposit/Withdraw Token 
     */

    struct token {
        bytes3 ticker; // Limiting the ticker length to 3 bytes max
        string tokenName; // User friendly token name
        address tokenAddress;
    }

    address public owner;
    mapping(bytes3 => token) public tokens;
    bytes3[] public tokensList;

    constructor() {
        owner = msg.sender;
    }

    function addNewToken(
        bytes3 ticker,
        string memory tokenName,
        address tokenAddress
    ) external isTickerAvailable(ticker) isOwner {
        token memory newToken = token(ticker, tokenName, tokenAddress);
        tokens[ticker] = newToken;
        tokensList.push(ticker);
    }

    mapping(address => mapping(bytes3 => uint256)) tradersBalances;

    // confusion
    function deposit(bytes3 ticker, uint256 amount)
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

    function withdraw(bytes3 ticker, uint256 amount)
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

    modifier isTokenExist(bytes3 ticker) {
        require(tokens[ticker].ticker != bytes3(0), "The token does not exist");
        _;
    }

    modifier isTickerAvailable(bytes3 ticker) {
        require(
            tokens[ticker].ticker == bytes3(0),
            "The ticker is already taken"
        );
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
}
