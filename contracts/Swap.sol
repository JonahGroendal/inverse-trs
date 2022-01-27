pragma solidity >=0.4.22 <0.9.0;

import "./IPrices.sol";
import "./IToken.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap {
    /// @notice minimum total value of leverage in underlying
    /// @dev prevents leverage `totalSupply` from growing too quickly and overflowing
    uint constant MIN_LEV_TOTAL_VALUE = 10**13;

    /// @notice Provides price of underlying in target asset
    IPrices private prices;

    /// @notice The stablecoin. Value pegged to target asset
    IToken private hedge;

    /// @notice The unstablecoin. Gives leveraged exposure to underlying asset.
    IToken private leverage;

    /// @notice The token collateralizing hedge token / underlying leverage token
    IToken private underlying;

    constructor(address _price, address _hedge, address _leverage, address _underlying) {
        prices     = IPrices(_price);
        hedge      = IToken(_hedge);
        leverage   = IToken(_leverage);
        underlying = IToken(_underlying);
    }

    /// @notice Buy `amount` hedge tokens
    function buyHedge(uint amount) public {
        uint value = hedgeValue(amount);
        require(value > 0);
        underlying.transferFrom(msg.sender, address(this), value + prices.hedgeBuyPremium());
        hedge.mint(msg.sender, amount);
    }

    /// @notice Sell `amount` hedge tokens
    function sellHedge(uint amount) public {
        uint value = hedgeValue(amount);
        require(value > 0);
        underlying.transfer(msg.sender, value - prices.hedgeSellPremium());
        hedge.burnFrom(msg.sender, amount);
    }

    /// @notice Buy `amount` leverage tokens
    function buyLeverage(uint amount) public {
        uint value = leverageValue(amount);
        require(value > 0);
        underlying.transferFrom(msg.sender, address(this), value + prices.leverageBuyPremium());
        leverage.mint(msg.sender, amount);
    }

    /// @notice Sell `amount` leverage tokens
    function sellLeverage(uint amount) public {
        uint value = leverageValue(amount);
        require(value > 0);
        underlying.transfer(msg.sender, value - prices.leverageSellPremium());
        leverage.burnFrom(msg.sender, amount);
    }

    /// @notice Value of `amount` leverage tokens in underlying tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    /// @dev Require minimum total value to prevent totalSupply overflow (still might be an issue idk)
    function leverageValue(uint amount) public view returns (uint) {
        if (leverage.totalSupply() == 0)
            return amount;
        uint totalValue = leverageTotalValue();
        require(totalValue > 10**15);
        return amount*totalValue/leverage.totalSupply();
    }

    /// @return Value in underlying of all leverage tokens
    function leverageTotalValue() internal view returns (uint) {
       return underlying.balanceOf(address(this)) - hedgeTotalValue(); 
    }

    /// @return Value in underlying of `amount` hedge tokens
    function hedgeValue(uint amount) internal view returns (uint) {
        uint lastPrice = prices.target();
        uint totalValue = hedge.totalSupply()*(10**18)/lastPrice;
        uint balance = underlying.balanceOf(address(this));
        if (balance < totalValue)
            return amount*balance/hedge.totalSupply();
        return amount*(10**18)/lastPrice;
    }

    /// @return Value in underlying of all hedge tokens
    function hedgeTotalValue() internal view returns (uint) {
        uint totalValue = hedge.totalSupply()*(10**18)/prices.target();
        uint balance = underlying.balanceOf(address(this));
        if (balance < totalValue)
            return balance;
        return totalValue;
    }
}
