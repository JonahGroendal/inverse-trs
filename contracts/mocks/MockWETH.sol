// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWETH is ERC20 {
    constructor(address[] memory accounts) ERC20("Wrapped ETH", "WETH") {
        for (uint i; i < accounts.length; i++) {
            _mint(accounts[i], 1000000*(10**18));
        }   
    }
}