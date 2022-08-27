pragma solidity ^0.8.11;

import "./IRates.sol";
import "./MathUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Rates is IRates, Ownable {
    using MathUtils for uint;

    uint constant ONE    = 10**18;
    uint constant ONE_26 = 10**26;
    uint constant COMPOUNDING_PERIOD = 3600;  // 1 hour

    AggregatorV3Interface internal priceFeed;

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

    constructor(address _priceFeed) {
        setPriceFeed(_priceFeed);
    }

    /// @return Nominal value of 1 underlying token in fixedLeg
    /// @dev underlying exchange rate + accrewed interest
    function fixedValue() public view returns (uint) {
        return underlying() * ONE_26 / accIntMul();
    }

    /// @return Value of underlying in denominating currency. 
    /// @dev Gets exchange rate from a price feed.
    function underlying() internal view returns (uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    /// @notice Accrewed interest multiplier. Nominal value of 1 fixedLeg token in denominating currency
    /// @return Target currency-fixed exchange rate, expressed as denominating currency per fixed. 26-decimal fixed-point 
    function accIntMul() public view returns (uint) {
        unchecked {
            return startValue * (interest*100000000).pow((block.timestamp - startTime) / COMPOUNDING_PERIOD) / ONE_26;
        }
    }

    /// @return Fee required to buy `amount` fixedLeg tokens
    /// @param value Value of trade in underlying
    function fixedBuyPremium(uint value) public view returns (uint) {
        return (value * ONE / (ONE - tolerance)) - value;
    }

    /// @return Fee required to sell `amount` fixedLeg tokens
    /// @param value Value of trade in underlying
    function fixedSellPremium(uint value) public view returns (uint) {
        return value - (value * ONE / (ONE + tolerance));
    }

    /// @return Fee required to buy `amount` floatLeg tokens
    /// @param value Value of trade in underlying
    /// @param fixedTotalValue Value in underlying of all fixedLeg tokens
    /// @param floatTotalValue Value in underlying of all floatLeg tokens
    function floatBuyPremium(uint value, uint fixedTotalValue, uint floatTotalValue) public view returns (uint) {
        if (floatTotalValue == 0) {
            return 0;
        }
        return (value - (value * ONE / (ONE + tolerance))) * fixedTotalValue / floatTotalValue;
    }

    /// @return Fee required to sell `amount` floatLeg tokens
    /// @param value Value of trade in underlying
    /// @param fixedTotalValue Value in underlying of all fixedLeg tokens
    /// @param floatTotalValue Value in underlying of all floatLeg tokens
    function floatSellPremium(uint value, uint fixedTotalValue, uint floatTotalValue) public view returns (uint) {
        if (floatTotalValue == 0) {
            return 0;
        }
        return ((value * ONE / (ONE - tolerance)) - value) * fixedTotalValue / floatTotalValue;
    }

    /// @notice Change the hourly interest rate. May represent a negative rate.
    /// @param _interest 18-decimal fixed-point. 1 + hourly interest rate.
    function setInterest(uint _interest) public onlyOwner {
        startValue = accIntMul();
        startTime = startTime + (((block.timestamp - startTime) / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD);
        interest = _interest;
    }

    function setMaxPriorityFee(uint _maxPriorityFee) public onlyOwner {
        maxPriorityFee = _maxPriorityFee;
    }

    function setTolerance(uint _tolerance) public onlyOwner {
        tolerance = _tolerance;
    }

    function setPriceFeed(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
}