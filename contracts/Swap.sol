pragma solidity ^0.8.11;

import "./ISwap.sol";
import "./Rates.sol";
import "./IToken.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap is ISwap, Rates {
    /// @notice Minimum allowed value of floatLeg in underlying
    /// @dev prevents floatLeg `totalSupply` from growing too quickly and overflowing
    uint constant MIN_FLOAT_TV = 10**13;

    /// @notice Tokens comprising the swap's fixed leg
    /// @notice Pegged to denominating asset + accrewed interest
    /// @dev Must use 18 decimals
    IToken public fixedLeg;

    /// @notice Tokens comprising the swap's floating leg
    /// @notice Pegged to [R/(R-1)]x leveraged underlying
    /// @dev Must use 18 decimals
    IToken public floatLeg;

    /// @notice Token collateralizing fixedLeg / underlying floatLeg
    /// @dev Must use 18 decimals
    IToken public underlying;

    function initialize(
        address _priceFeed,
        address _model,
        address _fixedLeg,
        address _floatLeg,
        address _underlying)
        public initializer
    {
        Rates.initialize(_priceFeed, _model);
        fixedLeg  = IToken(_fixedLeg);
        floatLeg  = IToken(_floatLeg);
        underlying = IToken(_underlying);
    }

    // function _authorizeUpgrade(address newImplementation)
    //     internal
    //     onlyOwner
    //     override
    // {}
/*
    constructor(address _priceFeed, address _model, address _fixedLeg, address _floatLeg, address _underlying)
    Rates(_priceFeed, _model)
    {
        fixedLeg   = IToken(_fixedLeg);
        floatLeg   = IToken(_floatLeg);
        underlying = IToken(_underlying);
    }
*/

    event BuyFixed (address indexed buyer,  uint amount, uint value);
    event SellFixed(address indexed seller, uint amount, uint value);
    event BuyFloat (address indexed buyer,  uint amount, uint value);
    event SellFloat(address indexed seller, uint amount, uint value);


    /// @notice limit TX priority to prevent fruntrunning price oracle updates
    /// @notice Also should delay trades to prevent trading on advanced price knowledge.
    /// @dev A selfish block producer could defeat this protection
    modifier limitedPriority {
        require(tx.gasprice - block.basefee <= maxPriorityFee, "Priority fee too high");
        _;
    }

    /// @notice Buy into fixed leg, minting `amount` tokens
    function buyFixed(uint amount, address to) public limitedPriority {
        uint potValue = _potValue();
        uint _accIntMul = accIntMul();
        (uint value, uint tv) = _fixedValue(amount, potValue, _accIntMul);
        require(value > 0, "Zero value trade");
        uint cost = value + fixedBuyPremium(value);
        underlying.transferFrom(msg.sender, address(this), cost);
        fixedLeg.mint(to, amount);
        _updateInterest(potValue + cost, tv, _accIntMul);
        emit BuyFixed(to, amount, value);
    }

    /// @notice Sell out of fixed leg, burning `amount` tokens
    function sellFixed(uint amount, address to) public limitedPriority {
        uint potValue = _potValue();
        uint _accIntMul = accIntMul();
        (uint value, uint tv) = _fixedValue(amount, potValue, _accIntMul);
        require(value > 0, "Zero value trade");
        uint cost = value - fixedSellPremium(value);
        underlying.transfer(to, cost);
        fixedLeg.burnFrom(msg.sender, amount);
        _updateInterest(potValue - cost, tv, _accIntMul);
        emit SellFixed(to, amount, value);
    }

    /// @notice Buy into floating leg, minting `amount` tokens
    function buyFloat(uint amount, address to) public limitedPriority {
        uint potValue = _potValue();
        uint _accIntMul = accIntMul();
        uint fixedTV = _fixedTV(potValue, _accIntMul);
        uint floatTV = potValue - fixedTV;
        uint value = _floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        uint cost = value + floatBuyPremium(value, fixedTV, floatTV);
        underlying.transferFrom(msg.sender, address(this), cost);
        floatLeg.mint(to, amount);
        _updateInterest(potValue + cost, fixedTV, _accIntMul);
        emit BuyFloat(to, amount, value);
    }

    /// @notice Sell out of floating leg, burning `amount` tokens
    function sellFloat(uint amount, address to) public limitedPriority {
        uint potValue = _potValue();
        uint _accIntMul = accIntMul();
        uint fixedTV = _fixedTV(potValue, _accIntMul);
        uint floatTV = potValue - fixedTV;
        uint value = _floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        uint cost = value - floatSellPremium(value, fixedTV, floatTV);
        underlying.transfer(to, cost);
        floatLeg.burnFrom(msg.sender, amount);
        _updateInterest(potValue - cost, fixedTV, _accIntMul);
        emit SellFloat(to, amount, value);
    }

    /// @notice Value in underlying of `amount` fixedLeg tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    function fixedValue(uint amount) public view returns (uint value, uint totalValue) {
        uint _accIntMul = accIntMul();
        return _fixedValue(amount, _potValue(), _accIntMul);
    }

    /// @notice Value in underlying ofixedLeg.totalSupply(),f `amount` floatLeg tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    function floatValue(uint amount) public view returns (uint) {
        uint potValue = _potValue();
        uint _accIntMul = accIntMul();
        return _floatValue(amount, potValue - _fixedTV(potValue, _accIntMul));
    }

    /// @dev Always called after a buy or sell but can be called by anyone at any time
    /// @dev Would behoove some stakeholders to call this after a price change
    function updateInterestRate() public {
        uint potValue = _potValue();
        uint _accIntMul = accIntMul();
        _updateInterest(potValue, _fixedTV(potValue, _accIntMul), _accIntMul);
    }

    function _floatValue(uint amount, uint totalValue) internal view returns (uint) {
        uint floatSupply = floatLeg.totalSupply();
        if (floatSupply == 0) {
            return amount;
        }
        //require(totalValue > MIN_FLOAT_TV, "Protecting against potential totalSupply overflow");
        return amount*totalValue/floatSupply;
    }
/*
    /// @return Value in underlying of all floatLeg tokens
    function floatTV(uint _fixedTV, uint _potValue) public view returns (uint) {
        return _potValue - _fixedTV;
    }
*/

    function _fixedValue(uint amount, uint potValue, uint _accIntMul) internal view returns (uint value, uint totalValue) {
        uint underlyingPrice = _underlyingPrice();
        uint supply = fixedLeg.totalSupply();
        uint nomValue = _fixedValueNominal(amount, _accIntMul, underlyingPrice);
        uint nomTV    = _fixedValueNominal(supply, _accIntMul, underlyingPrice);
        if (potValue < nomTV)
            return (amount*potValue/supply, potValue);
        return (nomValue, nomTV);
    }

    /// @notice Nominal value in underlying of all fixedLeg tokens
    function _fixedTV(uint potValue, uint _accIntMul) internal view returns (uint) {
        uint supply = fixedLeg.totalSupply();
        uint underlyingPrice = _underlyingPrice();
        uint nomValue = _fixedValueNominal(supply, _accIntMul, underlyingPrice);
        if (potValue < nomValue)
            return potValue;
        return nomValue;
    }

    function _potValue() internal view returns (uint) {
        return underlying.balanceOf(address(this));
    }
}
