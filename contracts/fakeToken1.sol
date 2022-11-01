// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeToken1 is ERC20 {
    constructor() ERC20("FT1", "Fake Token 1") {}

    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
