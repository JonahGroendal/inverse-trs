pragma solidity ^0.8.11;

import "./IRates.sol";
import "./MathUtils.sol";

abstract contract Rates is IRates {
    using MathUtils for uint;

    uint constant ONE    = 10**18;
    uint constant ONE_26 = 10**26;
    uint constant COMPOUNDING_PERIOD = 3600;  // 1 hour

    /// @notice Maximum allowed priority fee for trades
    /// @dev Prevents fruntrunning price oracle
    uint public maxPriorityFee = 3000000000;

    /// @notice Amount the price feed can safely deviate from the actual exchange rate due to latency
    /// @dev Used to calculate buy/sell premiums.
    /// @dev 18-decimal fixed-point percentage
    uint internal tolerance;

    /// @notice 1 + hourly interest rate. Rate can be negative
    /// @dev 18-decimal fixed-point
    uint public interest = ONE;

    /// @notice Timestamp of when interest began accrewing 
    uint internal startTime = block.timestamp;

    /// @notice Value of accumulated interest multiplier when interest began accrewing
    uint internal startValue = ONE_26;

    /// @return Nominal value of 1 underlying token in fixedLeg
    /// @dev underlying exchange rate + accrewed interest
    function fixedValue() public view virtual returns (uint) {
        return underlying() * ONE_26 / accIntMul();
    }

    /// @return Value of underlying in denominating currency. 
    /// @dev Gets exchange rate from a price feed.
    function underlying() internal view virtual returns (uint);

    /// @notice Accrewed interest multiplier. Nominal value of 1 fixedLeg token in denominating currency
    /// @return Target currency-fixed exchange rate, expressed as denominating currency per fixed. 26-decimal fixed-point 
    function accIntMul() public view override returns (uint) {
        unchecked {
            return startValue * (interest*100000000).pow((block.timestamp - startTime) / COMPOUNDING_PERIOD) / ONE_26;
        }
    }

    /// @return Fee required to buy `amount` fixedLeg tokens
    /// @param value Value of trade in underlying
    function fixedBuyPremium(uint value) public view override returns (uint) {
        return (value * ONE / (ONE - tolerance)) - value;
    }

    /// @return Fee required to sell `amount` fixedLeg tokens
    /// @param value Value of trade in underlying
    function fixedSellPremium(uint value) public view override returns (uint) {
        return value - (value * ONE / (ONE + tolerance));
    }

    /// @return Fee required to buy `amount` floatLeg tokens
    /// @param value Value of trade in underlying
    /// @param fixedTotalValue Value in underlying of all fixedLeg tokens
    /// @param floatTotalValue Value in underlying of all floatLeg tokens
    function floatBuyPremium(uint value, uint fixedTotalValue, uint floatTotalValue) public view override returns (uint) {
        if (floatTotalValue == 0) {
            return 0;
        }
        return (value - (value * ONE / (ONE + tolerance))) * fixedTotalValue / floatTotalValue;
    }

    /// @return Fee required to sell `amount` floatLeg tokens
    /// @param value Value of trade in underlying
    /// @param fixedTotalValue Value in underlying of all fixedLeg tokens
    /// @param floatTotalValue Value in underlying of all floatLeg tokens
    function floatSellPremium(uint value, uint fixedTotalValue, uint floatTotalValue) public view override returns (uint) {
        if (floatTotalValue == 0) {
            return 0;
        }
        return ((value * ONE / (ONE - tolerance)) - value) * fixedTotalValue / floatTotalValue;
    }

    // TODO: restrict access
    function setMaxPriorityFee(uint _maxPriorityFee) public override {
        maxPriorityFee = _maxPriorityFee;
    }

    // TODO: restrict access
    function setTolerance(uint _tolerance) public {
        tolerance = _tolerance;
    }

    /// @notice Change the hourly interest rate. May represent a negative rate.
    /// @param _interest 18-decimal fixed-point. 1 + hourly interest rate.
    // TODO: restrict access
    function setInterest(uint _interest) public {
        startValue = accIntMul();
        startTime = startTime + (((block.timestamp - startTime) / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD);
        interest = _interest;
    }
}