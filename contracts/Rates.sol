pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IPrice.sol";
import "./IModel.sol";
import "./Math.sol";

import "./IParameters.sol";

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

    IParameters public params;

    /// @notice 1 + hourly interest rate. Rate can be negative
    /// @dev 18-decimal fixed-point
    uint public interest;

    /// @notice Timestamp of when interest began accrewing
    /// @dev start at a perfect multiple of COMPOUNDING_PERIOD so all contracts are syncronized
    uint internal startTime;

    /// @notice Value of accumulated interest multiplier when interest began accrewing
    uint internal startValue;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event ParametersChanged(address params);
    // event PriceFeedChanged(address indexed priceFeed);
    // event MaxPriorityFeeChanged(uint maxPriorityFee);
    // event FeeChanged(uint tolerance);
    // event InterestModelChanged(address indexed model);

    function initialize(address _params) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        interest = ONE;
        startTime = (block.timestamp / COMPOUNDING_PERIOD) * COMPOUNDING_PERIOD;
        startValue = ONE_26;
        setParameters(_params);
    }

    /// @notice Nominal value of 1 fixedLeg token in underlying
    /// @dev underlying exchange rate + accrewed interest
    function fixedValueNominal(uint amount) public view returns (uint) {
        //return underlyingPrice() * ONE_26 / accIntMul();
        //return accIntMul() * ONE_10 / underlyingPrice();
        (, , IPrice price, , , ) = params.all();
        return _fixedValueNominal(amount, accIntMul(), price.get());
    }

    /// @notice Accrewed interest multiplier. Nominal value of 1 fixedLeg token in denominating currency
    /// @return Target currency-fixed exchange rate, expressed as denominating currency per fixed. 26-decimal fixed-point 
    function accIntMul() public view returns (uint) {
        unchecked {
            return startValue * (interest*ONE_8).pow((block.timestamp - startTime) / COMPOUNDING_PERIOD) / ONE_26;
        }
    }

    function setParameters(address _params) public onlyOwner {
        params = IParameters(_params);
        emit ParametersChanged(_params);
    }

    function _fixedValueNominal(uint amount, uint _accIntMul, uint underlyingPrice) internal pure returns (uint) {
        return amount * (_accIntMul / ONE_8) / underlyingPrice;
    }

    // /// @return Value of underlying in denominating currency. 
    // /// @dev Gets exchange rate from a price feed.
    // function _underlyingPrice() internal view returns (uint) {
    //     return price.get();
    // }

    /// @notice Update interest rate according to model
    function _updateInterest(int newRate, uint _accIntMul) internal {
        uint _interest = uint(int(ONE) + newRate);
        if (_interest != interest) {
            _setInterest(_interest, _accIntMul);
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