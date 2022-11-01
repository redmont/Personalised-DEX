// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Helper {
    bytes32 constant DAI = "DAI";

    address public owner;
    struct token {
        bytes32 ticker;
        string tokenName; // User friendly token name
        address tokenAddress;
    }

    bytes32[] public tokensList;

    mapping(bytes32 => token) public tokens;

    modifier isTokenExist(bytes32 ticker) {
        require(
            tokens[ticker].ticker != bytes32(0),
            "The token does not exist"
        );
        _;
    }

    modifier isTickerAvailable(bytes32 ticker) {
        require(
            tokens[ticker].ticker == bytes32(0),
            "The ticker is already taken"
        );
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
}
