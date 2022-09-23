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
    uint constant ONE_8 = 10**8;
    uint constant COMPOUNDING_PERIOD = 3600;  // 1 hour

    /// @notice Fee rate applied to notional value of trade.
    /// @notice Prevents soft frontrunning.
    /// @dev 18-decimal fixed-point
    uint public fee;

    /// @notice 1 + hourly interest rate. Rate can be negative
    /// @dev 18-decimal fixed-point
    uint public interest;

    /// @notice Interest rate model
    IModel public model;

    /// @notice Price of underlying in target asset
    IPrice internal price;

    /// @notice Timestamp of when interest began accrewing
    /// @dev start at a perfect multiple of COMPOUNDING_PERIOD so all contracts are syncronized
    uint internal startTime;

    /// @notice Value of accumulated interest multiplier when interest began accrewing
    uint internal startValue;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event PriceFeedChanged(address indexed priceFeed);
    event MaxPriorityFeeChanged(uint maxPriorityFee);
    event FeeChanged(uint tolerance);
    event InterestModelChanged(address indexed model);

    function initialize(address _price, address _model) public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        interest = ONE;
        startTime = (block.timestamp / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD;
        startValue = ONE_26;
        setPrice(_price);
        setModel(_model);
    }

    /// @notice Nominal value of 1 fixedLeg token in underlying
    /// @dev underlying exchange rate + accrewed interest
    function fixedValueNominal(uint amount) public view returns (uint) {
        //return underlyingPrice() * ONE_26 / accIntMul();
        //return accIntMul() * ONE_10 / underlyingPrice();
        return _fixedValueNominal(amount, accIntMul(), _underlyingPrice());
    }

    /// @notice Accrewed interest multiplier. Nominal value of 1 fixedLeg token in denominating currency
    /// @return Target currency-fixed exchange rate, expressed as denominating currency per fixed. 26-decimal fixed-point 
    function accIntMul() public view returns (uint) {
        unchecked {
            return startValue * (interest*ONE_8).pow((block.timestamp - startTime) / COMPOUNDING_PERIOD) / ONE_26;
        }
    }

    function setFee(uint _fee) public onlyOwner {
        fee = _fee;
        emit FeeChanged(_fee);
    }

    function setPrice(address _price) public onlyOwner {
        price = IPrice(_price);
        emit PriceFeedChanged(_price);
    }

    function setModel(address _model) public onlyOwner {
        model = IModel(_model);
        emit InterestModelChanged(_model);
    }

    function _fixedValueNominal(uint amount, uint _accIntMul, uint underlyingPrice) internal pure returns (uint) {
        return amount * (_accIntMul / ONE_8) / underlyingPrice;
    }

    /// @return Value of underlying in denominating currency. 
    /// @dev Gets exchange rate from a price feed.
    function _underlyingPrice() internal view returns (uint) {
        return price.get();
    }

    /// @notice Update interest rate according to model
    function _updateInterest(uint potValue, uint fixedTV, uint _accIntMul) internal {
        uint newRate = uint(int(ONE) + model.getInterestRate(potValue, fixedTV));
        if (newRate != interest) {
            _setInterest(newRate, _accIntMul);
        }
    }

    /// @notice Change the hourly interest rate. May represent a negative rate.
    /// @param _interest 18-decimal fixed-point. 1 + hourly interest rate.
    function _setInterest(uint _interest, uint _accIntMul) internal {
        startValue = _accIntMul;
        startTime = startTime + (((block.timestamp - startTime) / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD);
        interest = _interest;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}