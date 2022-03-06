pragma solidity ^0.8.11;

import "./IRates.sol";
import "./MathUtils.sol";

abstract contract Rates is IRates {
    using MathUtils for uint;

    uint constant ONE = 10**18;
    uint constant ONE_26 = 10**26;

    uint constant COMPOUNDING_PERIOD = 3600;

    /// @notice The amount `target` can safely deviate from the actual exchange rate due to latency
    /// @dev Used to calculate buy/sell premiums.
    /// @dev 18-decimal fixed-point percentage
    uint internal tolerance;

    /// @notice 1 + hourly interest rate. Rate can be negative
    uint public interest = ONE;
    /// @notice Timestamp of when interest began accrewing 
    uint internal startTime = block.timestamp;
    uint internal startValue = ONE_26;

    /// @return Target fixed-underlying exchange rate, expressed as fixed per underlying.
    function target() public view virtual returns (uint);

    /// @notice Value of fixed in denominating currency. Changes based on the interest rate
    /// @return Target currency-fixed exchange rate, expressed as denominating currency per fixed. 26-decimal fixed-point 
    function denomPerFixed() public view override returns (uint) {
        unchecked {
            return startValue * (interest*100000000).pow((block.timestamp - startTime) / COMPOUNDING_PERIOD) / ONE_26;
        }
    }

    function maxPriorityFee() public view override returns (uint) {
        return 3000000000;
    }


    function fixedBuyPremium(uint value) public view override returns (uint) {
        return (value * ONE / (ONE - tolerance)) - value;
    }

    function fixedSellPremium(uint value) public view override returns (uint) {
        return value - (value * ONE / (ONE + tolerance));
    }

    function floatBuyPremium(uint value, uint fixedTotalValue, uint floatTotalValue) public view override returns (uint) {
        if (floatTotalValue == 0) {
            return 0;
        }
        return (value - (value * ONE / (ONE + tolerance))) * fixedTotalValue / floatTotalValue;
    }

    function floatSellPremium(uint value, uint fixedTotalValue, uint floatTotalValue) public view override returns (uint) {
        if (floatTotalValue == 0) {
            return 0;
        }
        return ((value * ONE / (ONE - tolerance)) - value) * fixedTotalValue / floatTotalValue;
    }

    function setTolerance(uint _tolerance) public {
        tolerance = _tolerance;
    }

    /// @notice Change the hourly interest rate. May represent a negative rate.
    /// @param _interest 18-decimal fixed-point. 1 + hourly interest rate.
    // TODO: restrict access
    function setInterest(uint _interest) public {
        startValue = denomPerFixed();
        startTime = startTime + (((block.timestamp - startTime) / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD);
        interest = _interest;
    }
}