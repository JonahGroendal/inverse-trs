pragma solidity ^0.8.11;

import "./ISwap.sol";
import "./Rates.sol";
import "./IToken.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap is ISwap, Rates {
    // /// @notice Minimum allowed value of floatLeg in underlying
    // /// @dev prevents floatLeg `totalSupply` from growing too quickly and overflowing
    // uint constant MIN_FLOAT_TV = 10**13;

    IParameters public params;

    event BuyFixed (address indexed buyer,  uint amount, uint value);
    event SellFixed(address indexed seller, uint amount, uint value);
    event BuyFloat (address indexed buyer,  uint amount, uint value);
    event SellFloat(address indexed seller, uint amount, uint value);
    event ParametersChanged(address params);

    function initialize(address _params) public initializer {
        Rates.initialize();
        setParameters(_params);
    }

    /// @notice Buy into fixed leg, minting `amount` tokens
    function buyFixed(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken fixedLeg, , IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accIntMul = accIntMul();
        (uint value, uint tv) = _fixedValue(
            amount, price.get(), fixedLeg.totalSupply(), potValue, _accIntMul
        );
        require(value > 0, "Zero value trade");
        value += value * fee / ONE;
        underlying.transferFrom(msg.sender, address(this), value);
        fixedLeg.mint(to, amount);
        _updateInterest(model.getInterestRate(potValue + value, tv), _accIntMul);
        emit BuyFixed(to, amount, value);
    }

    /// @notice Sell out of fixed leg, burning `amount` tokens
    function sellFixed(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken fixedLeg, , IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accIntMul = accIntMul();
        (uint value, uint tv) = _fixedValue(
            amount, price.get(), fixedLeg.totalSupply(), potValue, _accIntMul
        );
        require(value > 0, "Zero value trade");
        value -= value * fee / ONE;
        underlying.transfer(to, value);
        fixedLeg.burnFrom(msg.sender, amount);
        _updateInterest(model.getInterestRate(potValue - value, tv), _accIntMul);
        emit SellFixed(to, amount, value);
    }

    /// @notice Buy into floating leg, minting `amount` tokens
    function buyFloat(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken fixedLeg, IToken floatLeg, IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accIntMul = accIntMul();
        uint fixedTV = _fixedTV(potValue, fixedLeg.totalSupply(), price.get(), _accIntMul);
        uint floatTV = potValue - fixedTV;
        uint value = _floatValue(amount, floatLeg.totalSupply(), floatTV);
        require(value > 0, "Zero value trade");
        if (floatTV > 0) {
            value += (value * fee / ONE) * fixedTV / floatTV;
        }
        underlying.transferFrom(msg.sender, address(this), value);
        floatLeg.mint(to, amount);
        _updateInterest(model.getInterestRate(potValue + value, fixedTV), _accIntMul);
        emit BuyFloat(to, amount, value);
    }

    /// @notice Sell out of floating leg, burning `amount` tokens
    function sellFloat(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken fixedLeg, IToken floatLeg, IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accIntMul = accIntMul();
        uint fixedTV = _fixedTV(potValue, fixedLeg.totalSupply(), price.get(), _accIntMul);
        uint floatTV = potValue - fixedTV;
        uint value = _floatValue(amount, floatLeg.totalSupply(), floatTV);
        require(value > 0, "Zero value trade");
        if (floatTV > 0) {
            value -= (value * fee / ONE) * fixedTV / floatTV;
        }
        underlying.transfer(to, value);
        floatLeg.burnFrom(msg.sender, amount);
        _updateInterest(model.getInterestRate(potValue - value, fixedTV), _accIntMul);
        emit SellFloat(to, amount, value);
    }

    /// @notice Value in underlying of `amount` fixedLeg tokens
    function fixedValue(uint amount) external view returns (uint, uint) {
        (, , IPrice price, IToken fixedLeg, , IToken underlying) = params.get();
        uint _accIntMul = accIntMul();
        return _fixedValue(amount, price.get(), fixedLeg.totalSupply(), underlying.balanceOf(address(this)), _accIntMul);
    }

    /// @notice Value in underlying of `amount` floatLeg tokens
    function floatValue(uint amount) external view returns (uint) {
        (, , IPrice price, IToken fixedLeg, IToken floatLeg, IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accIntMul = accIntMul();
        return _floatValue(amount, floatLeg.totalSupply(), potValue - _fixedTV(potValue, fixedLeg.totalSupply(), price.get(), _accIntMul));
    }

    /// @notice Nominal value of 1 fixedLeg token in underlying
    /// @dev underlying exchange rate + accrewed interest
    function fixedValueNominal(uint amount) external view returns (uint) {
        (, , IPrice price, , , ) = params.get();
        return _fixedValueNominal(amount, accIntMul(), price.get());
    }

    /// @dev Would behoove some stakeholders to call this after a price change
    function updateInterestRate() external {
        (, IModel model, IPrice price, IToken fixedLeg, , IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accIntMul = accIntMul();
        _updateInterest(model.getInterestRate(potValue, _fixedTV(potValue, fixedLeg.totalSupply(), price.get(), _accIntMul)), _accIntMul);
    }

    function setParameters(address _params) public onlyOwner {
        params = IParameters(_params);
        emit ParametersChanged(_params);
    }

    function _floatValue(uint amount, uint supply, uint totalValue) internal pure returns (uint) {
        if (supply == 0) {
            return amount;
        }
        return amount*totalValue/supply;
    }

    function _fixedValue(uint amount, uint price, uint supply, uint potValue, uint _accIntMul) internal pure returns (uint, uint) {
        uint nomValue = _fixedValueNominal(amount, _accIntMul, price);
        uint nomTV    = _fixedValueNominal(supply, _accIntMul, price);
        if (potValue < nomTV)
            return (amount*potValue/supply, potValue);
        return (nomValue, nomTV);
    }

    function _fixedTV(uint potValue, uint supply, uint price, uint _accIntMul) internal pure returns (uint) {
        uint nomValue = _fixedValueNominal(supply, _accIntMul, price);
        if (potValue < nomValue)
            return potValue;
        return nomValue;
    }

    function _fixedValueNominal(uint amount, uint _accIntMul, uint price) internal pure returns (uint) {
        return amount * (_accIntMul / ONE_8) / price;
    }
}
