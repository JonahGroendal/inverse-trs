pragma solidity ^0.8.11;

import "./ISwap.sol";
import "./Interest.sol";
import "./IParameters.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Swap is ISwap, Interest, OwnableUpgradeable, UUPSUpgradeable {
    // /// @notice Minimum allowed value of equityLeg in underlying
    // /// @dev prevents equityLeg `totalSupply` from growing too quickly and overflowing
    // uint constant MIN_EQUITY_TV = 10**13;

    IParameters public params;

    event BuyFloat  (address indexed buyer,  uint amount, uint value);
    event SellFloat (address indexed seller, uint amount, uint value);
    event BuyEquity (address indexed buyer,  uint amount, uint value);
    event SellEquity(address indexed seller, uint amount, uint value);
    event ParametersChanged(address params);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _params) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        Interest.initialize();
        setParameters(_params);
    }

    /// @notice Buy into floating leg, minting `amount` tokens
    function buyFloat(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken floatLeg, , IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accrewedMul = accrewedMul();
        (uint value, uint tv) = _floatValue(
            amount, price.get(), floatLeg.totalSupply(), potValue, _accrewedMul
        );
        require(value > 0, "Zero value trade");
        value += value * fee / ONE;
        underlying.transferFrom(msg.sender, address(this), value);
        floatLeg.mint(to, amount);
        _updateRate(model, potValue + value, tv, _accrewedMul);
        emit BuyFloat(to, amount, value);
    }

    /// @notice Sell out of floating leg, burning `amount` tokens
    function sellFloat(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken floatLeg, , IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accrewedMul = accrewedMul();
        (uint value, uint tv) = _floatValue(
            amount, price.get(), floatLeg.totalSupply(), potValue, _accrewedMul
        );
        require(value > 0, "Zero value trade");
        value -= value * fee / ONE;
        underlying.transfer(to, value);
        floatLeg.burnFrom(msg.sender, amount);
        _updateRate(model, potValue - value, tv, _accrewedMul);
        emit SellFloat(to, amount, value);
    }

    /// @notice Buy into equity leg, minting `amount` tokens
    function buyEquity(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken floatLeg, IToken equityLeg, IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accrewedMul = accrewedMul();
        uint floatTV = _floatTV(potValue, floatLeg.totalSupply(), price.get(), _accrewedMul);
        uint equityTV = potValue - floatTV;
        uint value = _equityValue(amount, equityLeg.totalSupply(), equityTV);
        require(value > 0, "Zero value trade");
        if (equityTV > 0) {
            value += (value * fee / ONE) * floatTV / equityTV;
        }
        underlying.transferFrom(msg.sender, address(this), value);
        equityLeg.mint(to, amount);
        _updateRate(model, potValue + value, floatTV, _accrewedMul);
        emit BuyEquity(to, amount, value);
    }

    /// @notice Sell out of equity leg, burning `amount` tokens
    function sellEquity(uint amount, address to) external {
        (uint fee, IModel model, IPrice price, IToken floatLeg, IToken equityLeg, IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accrewedMul = accrewedMul();
        uint floatTV = _floatTV(potValue, floatLeg.totalSupply(), price.get(), _accrewedMul);
        uint equityTV = potValue - floatTV;
        uint value = _equityValue(amount, equityLeg.totalSupply(), equityTV);
        require(value > 0, "Zero value trade");
        if (equityTV > 0) {
            value -= (value * fee / ONE) * floatTV / equityTV;
        }
        underlying.transfer(to, value);
        equityLeg.burnFrom(msg.sender, amount);
        _updateRate(model, potValue - value, floatTV, _accrewedMul);
        emit SellEquity(to, amount, value);
    }

    /// @notice Value in underlying of `amount` floatLeg tokens
    function floatValue(uint amount) external view returns (uint, uint) {
        (, , IPrice price, IToken floatLeg, , IToken underlying) = params.get();
        uint _accrewedMul = accrewedMul();
        return _floatValue(amount, price.get(), floatLeg.totalSupply(), underlying.balanceOf(address(this)), _accrewedMul);
    }

    /// @notice Value in underlying of `amount` equityLeg tokens
    function equityValue(uint amount) external view returns (uint) {
        (, , IPrice price, IToken floatLeg, IToken equityLeg, IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accrewedMul = accrewedMul();
        return _equityValue(amount, equityLeg.totalSupply(), potValue - _floatTV(potValue, floatLeg.totalSupply(), price.get(), _accrewedMul));
    }

    /// @notice Nominal value of 1 floatLeg token in underlying
    /// @dev underlying exchange rate + accrewed interest
    function floatValueNominal(uint amount) external view returns (uint) {
        (, , IPrice price, , , ) = params.get();
        return _floatValueNominal(amount, accrewedMul(), price.get());
    }

    /// @dev Would behoove some stakeholders to call this after a price change
    function updateInterestRate() external {
        (, IModel model, IPrice price, IToken floatLeg, , IToken underlying) = params.get();
        uint potValue = underlying.balanceOf(address(this));
        uint _accrewedMul = accrewedMul();
        _updateRate(model, potValue, _floatTV(potValue, floatLeg.totalSupply(), price.get(), _accrewedMul), _accrewedMul);
    }

    function setParameters(address _params) public onlyOwner {
        params = IParameters(_params);
        emit ParametersChanged(_params);
    }

    function _equityValue(uint amount, uint supply, uint totalValue) internal pure returns (uint) {
        if (supply == 0) {
            return amount;
        }
        return amount*totalValue/supply;
    }

    function _floatValue(uint amount, uint price, uint supply, uint potValue, uint _accrewedMul) internal pure returns (uint, uint) {
        uint nomValue = _floatValueNominal(amount, _accrewedMul, price);
        uint nomTV    = _floatValueNominal(supply, _accrewedMul, price);
        if (potValue < nomTV)
            return (amount*potValue/supply, potValue);
        return (nomValue, nomTV);
    }

    function _floatTV(uint potValue, uint supply, uint price, uint _accrewedMul) internal pure returns (uint) {
        uint nomValue = _floatValueNominal(supply, _accrewedMul, price);
        if (potValue < nomValue)
            return potValue;
        return nomValue;
    }

    function _floatValueNominal(uint amount, uint _accrewedMul, uint price) internal pure returns (uint) {
        return amount * (_accrewedMul / ONE_8) / price;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
