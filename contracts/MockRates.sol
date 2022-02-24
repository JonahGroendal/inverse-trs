pragma solidity ^0.8.11;

import "./IRates.sol";

contract MockRates is IRates {
    uint constant ONE = 10**18;

    uint private _target = 1000*(10**18);

    /// @notice The amount `target` can deviate from the actual exchange rate without opening arbitrage opportunities
    /// @dev Used to determine buy/sell premiums.
    /// @dev A "float" with 18 decimals, representing a percentage
    uint private _tolerance = 0;


    function target() public view override returns (uint) {
        return _target;
    }

    function maxPriorityFee() public view override returns (uint) {
        return 3000000000;
    }


    function hedgeBuyPremium(uint value) public view override returns (uint) {
        return (value * ONE / (ONE - _tolerance)) - value;
    }

    function hedgeSellPremium(uint value) public view override returns (uint) {
        return value - (value * ONE / (ONE + _tolerance));
    }

    function leverageBuyPremium(uint value, uint hedgeTotalValue, uint leverageTotalValue) public view override returns (uint) {
        if (leverageTotalValue == 0) {
            return 0;
        }
        return (value - (value * ONE / (ONE + _tolerance))) * hedgeTotalValue / leverageTotalValue;
    }
    
    function leverageSellPremium(uint value, uint hedgeTotalValue, uint leverageTotalValue) public view override returns (uint) {
        if (leverageTotalValue == 0) {
            return 0;
        }
        return ((value * ONE / (ONE - _tolerance)) - value) * hedgeTotalValue / leverageTotalValue;
    }

    function setTarget(uint t) public {
        _target = t;
    }

    function setTolerance(uint t) public {
        _tolerance = t;
    }
}