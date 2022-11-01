// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dai is ERC20 {
    constructor() ERC20("DAI", "FAKE DAI Stablecoin") {}

    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
