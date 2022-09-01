pragma solidity ^0.8.11;

import "./ISwap.sol";
import "./IRates.sol";
import "./IToken.sol";

/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral but the system needs to be redeployed.
contract Swap is ISwap {
    uint constant ONE = 10**18;

    /// @notice Minimum allowed value of floatLeg in underlying
    /// @dev prevents floatLeg `totalSupply` from growing too quickly and overflowing
    uint constant MIN_FLOAT_TV = 10**13;

    /// @notice Tracks exchange rates, accrewed interest, and premiums
    IRates public rates;

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

    constructor(address _rates, address _fixedLeg, address _floatLeg, address _underlying) {
        rates      = IRates(_rates);
        fixedLeg   = IToken(_fixedLeg);
        floatLeg   = IToken(_floatLeg);
        underlying = IToken(_underlying);
    }

    /// @notice limit TX priority to prevent fruntrunning price oracle updates
    /// @notice Also should delay trades to prevent trading on advanced price knowledge.
    modifier limitedPriority {
        require(tx.gasprice - block.basefee <= rates.maxPriorityFee(), "Priority fee too high");
        _;
    }

    /// @notice Buy into fixed leg, minting `amount` tokens
    function buyFixed(uint amount, address to) public limitedPriority {
        uint value = fixedValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.fixedBuyPremium(value)
        );
        fixedLeg.mint(to, amount);
    }

    /// @notice Sell out of fixed leg, burning `amount` tokens
    function sellFixed(uint amount, address to) public limitedPriority {
        uint value = fixedValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transfer(
            to,
            value - rates.fixedSellPremium(value)
        );
        fixedLeg.burnFrom(msg.sender, amount);
    }

    /// @notice Buy into floating leg, minting `amount` tokens
    function buyFloat(uint amount, address to) public limitedPriority {
        uint fixedTV = fixedTotalNomValue(rates.fixedValue());
        uint floatTV = floatTotalValue(fixedTV);
        uint value   = floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.floatBuyPremium(value, fixedTV, floatTV)
        );
        floatLeg.mint(to, amount);
    }

    /// @notice Sell out of floating leg, burning `amount` tokens
    function sellFloat(uint amount, address to) public limitedPriority {
        uint fixedTV = fixedTotalNomValue(rates.fixedValue());
        uint floatTV = floatTotalValue(fixedTV);
        uint value   = floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        underlying.transfer(
            to,
            value - rates.floatSellPremium(value, fixedTV, floatTV)
        );
        floatLeg.burnFrom(msg.sender, amount);
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
    function floatTotalValue(uint _fixedTotalNomValue) public view returns (uint) {
        uint _potValue = potValue();
        if (_potValue > _fixedTotalNomValue) {
            return _potValue - _fixedTotalNomValue;
        }
        return 0;
    }

    /// @return Value in underlying of `amount` fixedLeg tokens
    function fixedValue(uint amount) public view returns (uint) {
        uint value = rates.fixedValue();
        uint totalValue = fixedTotalNomValue(value);
        uint _potValue = potValue();
        if (_potValue < totalValue)
            return amount*_potValue/fixedLeg.totalSupply();
        return amount*ONE/value;
    }

    /// @return Nominal value in underlying of all fixedLeg tokens
    /// @param value Nominal value in underlying of 1 fixedLeg token
    function fixedTotalNomValue(uint value) public view returns (uint) {
        return fixedLeg.totalSupply()*ONE/value;
    }

    function potValue() public view returns (uint) {
        return underlying.balanceOf(address(this));
    }
}
