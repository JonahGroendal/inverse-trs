pragma solidity >=0.4.22 <0.9.0;

import "./IPrices.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap {
    /// @notice Provides price of underlying in target asset
    Prices prices;

    /// @notice The stablecoin. Value pegged to target asset
    ERC20 private hedge;

    /// @notice The unstablecoin. Gives leveraged exposure to underlying asset.
    ERC20 private leverage;

    /// @notice The token collateralizing hedge token / underlying leverage token
    ERC20 private underlying;

    constructor(address _price, address _hedge, address _leverage, address _underlying) {
        price      = PriceOracle(_price);
        hedge      = ERC20(_hedge);
        leverage   = ERC20(_leverage);
        underlying = ERC20(_underlying);
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
        hedge.burn(msg.sender, amount);
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
        leverage.burn(amount);
    }

    /// @notice Value of `amount` leverage tokens in underlying tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    /// @dev Require minimum total value to prevent totalSupply overflow (still might be an issue idk)
    function leverageValue(uint amount) public view returns (uint) {
        if (leverage.totalSupply() == 0)
            return amount;
        uint totalValue = leverageTotalValue();
        require(totalValue > 10^15);
        return amount*totalValue/leverage.totalSupply();
    }

    /// @return Value in underlying of all leverage tokens
    function leverageTotalValue() internal view returns (uint) {
       return underlying.balanceOf(address(this)) - hedgeTotalValue(); 
    }

    /// @return Value in underlying of `amount` hedge tokens
    function hedgeValue(uint amount) internal view returns (uint) {
        uint lastPrice = prices.target();
        uint totalValue = hedge.totalSupply()*10^18/lastPrice;
        uint balance = underlying.balanceOf(address(this));
        if (balance < totalValue)
            return amount*balance/hedge.totalSupply();
        return amount*10^18/lastPrice;
    }

    /// @return Value in underlying of all hedge tokens
    function hedgeTotalValue() internal view returns (uint) {
        uint totalValue = hedge.totalSupply()*10^18/prices.target();
        uint balance = underlying.balanceOf(address(this));
        if (balance < totalValue)
            return balance;
        return totalValue;
    }
}
