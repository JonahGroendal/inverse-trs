pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IToken.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap {
    /// @notice minimum total value of leverage in underlying
    /// @dev prevents leverage `totalSupply` from growing too quickly and overflowing
    uint constant MIN_LEV_TOTAL_VALUE = 10**13;

    /// @notice Provides price of underlying in target asset
    IRates private rates;

    /// @notice The stablecoin. Value pegged to target asset
    IToken private hedge;

    /// @notice The unstablecoin. Gives leveraged exposure to underlying asset.
    IToken private leverage;

    /// @notice The token collateralizing hedge token / underlying leverage token
    IToken private underlying;

    constructor(address _rates, address _hedge, address _leverage, address _underlying) {
        rates      = IRates(_rates);
        hedge      = IToken(_hedge);
        leverage   = IToken(_leverage);
        underlying = IToken(_underlying);
    }

    /// @notice limit TX priority to prevent fruntrunning price oracle updates
    /// @notice Also should delay transaction to prevent trading on advanced price knowledge.
    modifier limitedPriority {
        require(tx.gasprice - block.basefee <= rates.maxPriorityFee(), "Priority fee too high");
        _;
    }

    /// @notice Buy `amount` hedge tokens
    function buyHedge(uint amount) public limitedPriority {
        uint value = hedgeValue(amount);
        require(value > 0, "zero value");
        underlying.transferFrom(msg.sender, address(this), value + rates.hedgeBuyPremium(value));
        hedge.mint(msg.sender, amount);
    }

    /// @notice Sell `amount` hedge tokens
    function sellHedge(uint amount) public limitedPriority {
        uint value = hedgeValue(amount);
        require(value > 0, "zero value");
        underlying.transfer(msg.sender, value - rates.hedgeSellPremium(value));
        hedge.burnFrom(msg.sender, amount);
    }

    /// @notice Buy `amount` leverage tokens
    function buyLeverage(uint amount) public limitedPriority {
        uint value = leverageValue(amount);
        require(value > 0, "zero value");
        underlying.transferFrom(msg.sender, address(this), value + rates.leverageBuyPremium(value));
        leverage.mint(msg.sender, amount);
    }

    /// @notice Sell `amount` leverage tokens
    function sellLeverage(uint amount) public limitedPriority {
        uint value = leverageValue(amount);
        require(value > 0, "zero value");
        underlying.transfer(msg.sender, value - rates.leverageSellPremium(value));
        leverage.burnFrom(msg.sender, amount);
    }

    /// @notice Value of `amount` leverage tokens in underlying tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    /// @dev Require minimum total value to prevent totalSupply overflow (still might be an issue idk)
    function leverageValue(uint amount) public view returns (uint) {
        if (leverage.totalSupply() == 0)
            return amount;
        uint totalValue = leverageTotalValue();
        require(totalValue > 10**15, "protecting against potential totalSupply overflow");
        return amount*totalValue/leverage.totalSupply();
    }

    /// @return Value in underlying of all leverage tokens
    function leverageTotalValue() internal view returns (uint) {
       return underlying.balanceOf(address(this)) - hedgeTotalValue(); 
    }

    /// @return Value in underlying of `amount` hedge tokens
    function hedgeValue(uint amount) internal view returns (uint) {
        uint lastPrice = rates.target();
        uint totalValue = hedge.totalSupply()*(10**18)/lastPrice;
        uint balance = underlying.balanceOf(address(this));
        if (balance < totalValue)
            return amount*balance/hedge.totalSupply();
        return amount*(10**18)/lastPrice;
    }

    /// @return Value in underlying of all hedge tokens
    function hedgeTotalValue() internal view returns (uint) {
        uint totalValue = hedge.totalSupply()*(10**18)/rates.target();
        uint balance = underlying.balanceOf(address(this));
        if (balance < totalValue)
            return balance;
        return totalValue;
    }
}
