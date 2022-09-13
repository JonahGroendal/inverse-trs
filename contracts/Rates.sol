pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IPrice.sol";
import "./IModel.sol";
import "./Math.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Tracks exchange rate, interest rate, accrewed interest and premiums
contract Rates is IRates, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using Math for uint;

    uint constant ONE    = 10**18;
    uint constant ONE_26 = 10**26;
    uint constant COMPOUNDING_PERIOD = 3600;  // 1 hour

    /// @notice The price feed
    IPrice internal price;

    /// @notice Maximum allowed priority fee for trades
    /// @dev Prevents fruntrunning price oracle
    uint public maxPriorityFee;

    /// @notice Amount the price feed can safely deviate from the actual exchange rate due to latency
    /// @dev Used to calculate buy/sell premiums.
    /// @dev 18-decimal fixed-point percentage
    uint public tolerance;

    /// @notice 1 + hourly interest rate. Rate can be negative
    /// @dev 18-decimal fixed-point
    uint public interest;

    /// @notice Timestamp of when interest began accrewing
    /// @dev start at a perfect multiple of COMPOUNDING_PERIOD so all contracts are syncronized
    uint internal startTime;

    /// @notice Value of accumulated interest multiplier when interest began accrewing
    uint internal startValue;

    /// @notice Interest rate model
    IModel public model;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event PriceFeedChanged(address indexed priceFeed);
    event MaxPriorityFeeChanged(uint maxPriorityFee);
    event ToleranceChanged(uint tolerance);
    event InterestModelChanged(address indexed model);

    function initialize(address _price, address _model) public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        maxPriorityFee = 3000000000;
        interest = ONE;
        startTime = (block.timestamp / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD;
        startValue = ONE_26;
        setPrice(_price);
        setModel(_model);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /// @return Nominal value of 1 underlying token in fixedLeg
    /// @dev underlying exchange rate + accrewed interest
    function fixedValue() public view returns (uint) {
        return underlyingValue() * ONE_26 / accIntMul();
    }

    /// @return Value of underlying in denominating currency. 
    /// @dev Gets exchange rate from a price feed.
    function underlyingValue() internal view returns (uint) {
        return price.get();
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

    function setMaxPriorityFee(uint _maxPriorityFee) public onlyOwner {
        maxPriorityFee = _maxPriorityFee;
        emit MaxPriorityFeeChanged(_maxPriorityFee);
    }

    function setTolerance(uint _tolerance) public onlyOwner {
        tolerance = _tolerance;
        emit ToleranceChanged(_tolerance);
    }

    function setPrice(address _price) public onlyOwner {
        price = IPrice(_price);
        emit PriceFeedChanged(_price);
    }

    function setModel(address _model) public onlyOwner {
        model = IModel(_model);
        emit InterestModelChanged(_model);
    }

    /// @notice Update interest rate according to model
    function _updateInterest(uint potValue, uint fixedTV) internal {
        uint newRate = uint(int(ONE) + model.getInterestRate(potValue, fixedTV));
        if (newRate != interest) {
            _setInterest(newRate);
        }
    }

    /// @notice Change the hourly interest rate. May represent a negative rate.
    /// @param _interest 18-decimal fixed-point. 1 + hourly interest rate.
    function _setInterest(uint _interest) internal {
        startValue = accIntMul();
        startTime = startTime + (((block.timestamp - startTime) / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD);
        interest = _interest;
    }
}