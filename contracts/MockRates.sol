pragma solidity ^0.8.11;

import "./Rates.sol";

contract MockRates is Rates {

    uint internal _target = 1000*ONE;

    /// @return Target hedge-underlying exchange rate, expressed as hedge per underlying.
    function target() public view override returns (uint) {
        return _target * ONE_26 / denomPerFixed();
    }

    function setTarget(uint t) public {
        _target = t;
    }

}