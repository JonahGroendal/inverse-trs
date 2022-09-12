pragma solidity ^0.8.11;

import "@openzeppelin/contracts/governance/TimelockController.sol";
 
contract Timelock is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors)
        TimelockController(minDelay, proposers, executors)
    {}
}
