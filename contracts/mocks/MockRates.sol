pragma solidity >=0.4.22 <0.9.0;

import "../IRates.sol";

contract MockRates is IRates {
    uint private _target = 1000*(10**18);
    uint private _targetAt = _target;
    uint private _targetAfterDelay = _target;
    uint private _depositBaseRate;

    function target() public view override returns (uint price, uint roundId) {
        price = _target;
        roundId = 1;
    }

    function targetAt(uint timestamp, uint roundId) public view override returns (uint) {
        return _targetAt;
    }

    /// @return what the target price was some seconds after the given timestamp
    /// @param roundId roundId to start looking for the timestamp
    function targetAfterDelay(uint timestamp, uint roundId) public view override returns (uint) {
        return _targetAfterDelay;
    }

    function buyPremium(uint value, uint levRatio) public pure override returns (uint) {
        return 0;
    }
    function sellPremium(uint value, uint levRatio) public pure override returns (uint) {
        return 0;
    }

    function deposit(uint value, uint levRatio) public view override returns (uint) {
        return value * _depositBaseRate * levRatio / (10**36);
    }

    function setTarget(uint t) public {
        _target = t;
    }

    function setTargetAt(uint t) public {
        _targetAt = t;
    }

    function setTargetAfterDelay(uint t) public {
        _targetAfterDelay = t;
    }

    function setDepositBaseRate(uint r) public {
        _depositBaseRate = r;
    }
}