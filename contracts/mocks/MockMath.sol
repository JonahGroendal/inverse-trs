pragma solidity ^0.8.11;

import "../Math.sol";

contract MockMath {
    using Math for uint;
    uint i;

    function testPow(uint base, uint n) public view returns (uint) {
        return base.pow(n);
    }

    function testGasPow(uint base, uint n) public {
        base.pow(n);
    }
}