// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./baseContract.sol";

contract Traders is Helper {
    /* This contract has following functionalities
     1. Create Limit order
     2. Create Market order
     */

    mapping(address => mapping(bytes32 => uint256)) public tradersBalances;

    function getBalance(bytes32 ticker, address traderAddress)
        public
        view
        isTokenExist(ticker)
        returns (uint256)
    {
        return tradersBalances[traderAddress][ticker];
    }
}
