// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomToken is ERC20{
    constructor(string memory name, string memory symbol, address creator, address user1, address user2) ERC20(name,symbol) {
        _mint(creator, 10000000);
        _mint(user1, 10000000);
        _mint(user2, 10000000);
    }
}