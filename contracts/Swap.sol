pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IToken.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap {
    uint constant ONE = 10**18;

    /// @notice minimum total value of leverage in underlying
    /// @dev prevents leverage `totalSupply` from growing too quickly and overflowing
    uint constant MIN_LEV_TOTAL_VALUE = 10**13;

    /// @notice Provides price of underlying in target asset
    IRates private rates;

    /// @notice The stablecoin. Value pegged to target asset
    /// @dev Must use 18 decimals
    IToken private hedge;

    /// @notice The unstablecoin. Gives leveraged exposure to underlying asset.
    /// @dev Must use 18 decimals
    IToken private leverage;

    /// @notice The token collateralizing hedge token / underlying leverage token
    /// @dev Must use 18 decimals
    IToken private underlying;

    constructor(address _rates, address _hedge, address _leverage, address _underlying) {
        rates      = IRates(_rates);
        hedge      = IToken(_hedge);
        leverage   = IToken(_leverage);
        underlying = IToken(_underlying);
    }

    /// @notice limit TX priority to prevent fruntrunning price oracle updates
    /// @notice Also should delay trades to prevent trading on advanced price knowledge.
    modifier limitedPriority {
        require(tx.gasprice - block.basefee <= rates.maxPriorityFee(), "Priority fee too high");
        _;
    }

    /// @notice Buy `amount` hedge tokens
    function buyHedge(uint amount) public limitedPriority {
        uint value = hedgeValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(msg.sender, address(this), value + rates.hedgeBuyPremium(value));
        hedge.mint(msg.sender, amount);
    }

    /// @notice Sell `amount` hedge tokens
    function sellHedge(uint amount) public limitedPriority {
        uint value = hedgeValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transfer(msg.sender, value - rates.hedgeSellPremium(value));
        hedge.burnFrom(msg.sender, amount);
    }

    // @notice Buy `amount` leverage tokens
    function buyLeverage(uint amount) public limitedPriority {
        uint hedgeTV    = hedgeTotalNomValue(rates.target());
        uint leverageTV = leverageTotalValue(hedgeTV);
        uint value      = leverageValue(amount, leverageTV);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.leverageBuyPremium(value, hedgeTV, leverageTV)
        );
        leverage.mint(msg.sender, amount);
    }

    /// @notice Sell `amount` leverage tokens
    function sellLeverage(uint amount) public limitedPriority {
        uint hedgeTV    = hedgeTotalNomValue(rates.target());
        uint leverageTV = leverageTotalValue(hedgeTV);
        uint value      = leverageValue(amount, leverageTV);
        require(value > 0, "Zero value trade");
        underlying.transfer(
            msg.sender,
            value - rates.leverageSellPremium(value, hedgeTV, leverageTV)
        );
        leverage.burnFrom(msg.sender, amount);
    }

    /// @return value Value in underlying of `amount` leverage tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    /// @dev Require minimum total value to prevent totalSupply overflow (still might be an issue idk)
    function leverageValue(uint amount, uint totalValue) public view returns (uint) {
        if (leverage.totalSupply() == 0) {
            return amount;
        }
        require(totalValue > MIN_LEV_TOTAL_VALUE, "Protecting against potential totalSupply overflow");
        return amount*totalValue/leverage.totalSupply();
    }

    /// @return Value in underlying of all leverage tokens
    function leverageTotalValue(uint _hedgeTotalNomValue) internal view returns (uint) {
        uint _potValue = potValue();
        if (_potValue > _hedgeTotalNomValue) {
            return _potValue - _hedgeTotalNomValue;
        }
        return 0;
    }

    /// @return Value in underlying of `amount` hedge tokens
    function hedgeValue(uint amount) internal view returns (uint) {
        uint target = rates.target();
        uint totalValue = hedgeTotalNomValue(lastPrice);
        uint _potValue = potValue();
        if (_potValue < totalValue)
            return amount*_potValue/hedge.totalSupply();
        return amount*ONE/target;
    }

    /// @return Nominal value in underlying of all hedge tokens
    function hedgeTotalNomValue(uint targetRate) internal view returns (uint) {
        return hedge.totalSupply()*ONE/targetRate;
    }

    function potValue() internal view returns (uint) {
        return underlying.balanceOf(address(this));
    }
}
