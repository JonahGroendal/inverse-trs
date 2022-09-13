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
    modifier limitedPriority {
        require(tx.gasprice - block.basefee <= maxPriorityFee, "Priority fee too high");
        _;
    }

    /// @notice Buy into fixed leg, minting `amount` tokens
    function buyFixed(uint amount, address to) public limitedPriority {
        uint value = fixedValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + fixedBuyPremium(value)
        );
        fixedLeg.mint(to, amount);
        updateInterest();
        emit BuyFixed(to, amount, value);
    }

    /// @notice Sell out of fixed leg, burning `amount` tokens
    function sellFixed(uint amount, address to) public limitedPriority {
        uint value = fixedValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transfer(
            to,
            value - fixedSellPremium(value)
        );
        fixedLeg.burnFrom(msg.sender, amount);
        updateInterest();
        emit SellFixed(to, amount, value);
    }

    /// @notice Buy into floating leg, minting `amount` tokens
    function buyFloat(uint amount, address to) public limitedPriority {
        uint fixedTV = fixedTV(fixedValue());
        uint floatTV = floatTV(fixedTV);
        uint value   = floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + floatBuyPremium(value, fixedTV, floatTV)
        );
        floatLeg.mint(to, amount);
        updateInterest();
        emit BuyFloat(to, amount, value);
    }

    /// @notice Sell out of floating leg, burning `amount` tokens
    function sellFloat(uint amount, address to) public limitedPriority {
        uint fixedTV = fixedTV(fixedValue());
        uint floatTV = floatTV(fixedTV);
        uint value   = floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        underlying.transfer(
            to,
            value - floatSellPremium(value, fixedTV, floatTV)
        );
        floatLeg.burnFrom(msg.sender, amount);
        updateInterest();
        emit SellFloat(to, amount, value);
    }

    /// @return Value in underlying of `amount` floatLeg tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    /// @dev Require minimum total value to prevent totalSupply overflow
    function floatValue(uint amount, uint totalValue) public view returns (uint) {
        if (floatLeg.totalSupply() == 0) {
            return amount;
        }
        require(totalValue > MIN_FLOAT_TV, "Protecting against potential totalSupply overflow");
        return amount*totalValue/floatLeg.totalSupply();
    }

    /// @return Value in underlying of all floatLeg tokens
    function floatTV(uint _fixedTV) public view returns (uint) {
        uint _potValue = potValue();
        if (_potValue > _fixedTV) {
            return _potValue - _fixedTV;
        }
        return 0;
    }

    /// @return Value in underlying of `amount` fixedLeg tokens
    function fixedValue(uint amount) public view returns (uint) {
        uint value = fixedValue();
        uint totalValue = fixedTV(value);
        uint _potValue = potValue();
        if (_potValue < totalValue)
            return amount*_potValue/fixedLeg.totalSupply();
        return amount*ONE/value;
    }

    /// @return Nominal value in underlying of all fixedLeg tokens
    /// @param value Nominal value in underlying of 1 fixedLeg token
    function fixedTV(uint value) public view returns (uint) {
        return fixedLeg.totalSupply()*ONE/value;
    }

    function potValue() public view returns (uint) {
        return underlying.balanceOf(address(this));
    }

    /// @dev Always called after a buy or sell but can be called by anyone at any time
    /// @dev Would behoove some stakeholders to call this after a price change
    function updateInterest() public {
        _updateInterest(potValue(), fixedTV(fixedValue()));
    }
}
