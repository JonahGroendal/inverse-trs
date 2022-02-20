pragma solidity >=0.4.22 <0.9.0;

import "../IRates.sol";

contract MockRates is IRates {
    uint private _target = 1000*(10**18);

    function target() public view override returns (uint price, uint roundId) {
        price = _target;
        roundId = 1;
    }

    function targetAt(uint timestamp, uint roundId) public view override returns (uint) {
        return _target;
    }

    /// @return what the target price was some seconds after the given timestamp
    /// @param roundId roundId to start looking for the timestamp
    function targetAfterDelay(uint timestamp, uint roundId) public view override returns (uint) {
        return _target;
    }

    function buyPremium(uint value, uint levRatio) public pure override returns (uint) {
        return 0;
    }
    function sellPremium(uint value, uint levRatio) public pure override returns (uint) {
        return 0;
    }

    function deposit(uint value, uint levRatio) public pure override returns (uint) {
        return 0;
    }

    function setTarget(uint t) public {
        _target = t;
    }
}