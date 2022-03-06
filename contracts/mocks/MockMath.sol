pragma solidity ^0.8.11;

import "../MathUtils.sol";

contract MockMath {
    using MathUtils for uint;
    uint i;

    function testPow(uint base, uint n) public view returns (uint) {
        return base.pow(n);
    }

    function testGasPow(uint base, uint n) public {
        base.pow(n);
    }
}