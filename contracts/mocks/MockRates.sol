pragma solidity ^0.8.11;

import "../Rates.sol";

contract MockRates is Rates {

    uint internal _target = 1000*ONE;

    function underlying() internal view override returns (uint) {
        return _target;
    }

    function setTarget(uint t) public {
        _target = t;
    }

}