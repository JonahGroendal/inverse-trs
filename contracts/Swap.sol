pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IToken.sol";

/// @notice The swap contract
/// @notice Mints/burns fixed/floating leg tokens and holds on to the collateral
contract Swap {
    uint constant ONE = 10**18;

    /// @notice Minimum allowed value of floatLeg in underlying
    /// @dev prevents floatLeg `totalSupply` from growing too quickly and overflowing
    uint constant MIN_FLOAT_TV = 10**13;

    uint public targetMul;

    /// @notice Tracks exchange rates, accrewed interest, premiums
    IRates private rates;

    /// @notice Tokens comprising the swap's fixed leg
    /// @notice Pegged to denominating asset + accrewed interest
    /// @dev Must use 18 decimals
    IToken private fixedLeg;

    /// @notice Tokens comprising the swap's floating leg
    /// @notice Pegged to [R/(R-1)]x leveraged underlying
    /// @dev Must use 18 decimals
    IToken private floatLeg;

    /// @notice Token collateralizing fixedLeg / underlying floatLeg
    /// @dev Must use 18 decimals
    IToken private underlying;

    constructor(address _rates, address _fixedLeg, address _floatLeg, address _underlying) {
        rates      = IRates(_rates);
        fixedLeg   = IToken(_fixedLeg);
        floatLeg   = IToken(_floatLeg);
        underlying = IToken(_underlying);
        targetMul  = ONE;
    }

    /// @notice limit TX priority to prevent fruntrunning price oracle updates
    /// @notice Also should delay trades to prevent trading on advanced price knowledge.
    modifier limitedPriority {
        require(tx.gasprice - block.basefee <= rates.maxPriorityFee(), "Priority fee too high");
        _;
    }

    /// @notice Buy into fixed leg, minting `amount` tokens
    function buyFixed(uint amount) public limitedPriority {
        checkSolvency();
        uint value = fixedValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.fixedBuyPremium(value)
        );
        fixedLeg.mint(msg.sender, amount);
    }

    /// @notice Sell out of fixed leg, burning `amount` tokens
    function sellFixed(uint amount) public limitedPriority {
        checkSolvency();
        uint value = fixedValue(amount);
        require(value > 0, "Zero value trade");
        underlying.transfer(
            msg.sender,
            value - rates.fixedSellPremium(value)
        );
        fixedLeg.burnFrom(msg.sender, amount);
    }

    /// @notice Buy into floating leg, minting `amount` tokens
    function buyFloat(uint amount) public limitedPriority {
        checkSolvency();
        uint fixedTV = fixedTotalNomValue(rates.fixedValue(targetMul));
        uint floatTV = floatTotalValue(fixedTV);
        uint value   = floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.floatBuyPremium(value, fixedTV, floatTV)
        );
        floatLeg.mint(msg.sender, amount);
    }

    /// @notice Sell out of floating leg, burning `amount` tokens
    function sellFloat(uint amount) public limitedPriority {
        checkSolvency();
        uint fixedTV = fixedTotalNomValue(rates.fixedValue(targetMul));
        uint floatTV = floatTotalValue(fixedTV);
        uint value   = floatValue(amount, floatTV);
        require(value > 0, "Zero value trade");
        //require(floatTV - value >= MIN_FLOAT_TV, "Insufficient collateral");
        require(floatTV >= value, "Insufficient collateral");
        underlying.transfer(
            msg.sender,
            value - rates.floatSellPremium(value, fixedTV, floatTV)
        );
        floatLeg.burnFrom(msg.sender, amount);
    }

    function checkSolvency() public {
        uint assets = potValue();
        uint liabilities = fixedTotalNomValue(rates.fixedValue(targetMul));
        //require(assets > MIN_FLOAT_TV);
        // if (assets < MIN_FLOAT_TV) {
        //     // in case somebody sends some underlying to this contract
        //     uint floatSupply = floatLeg.totalSupply();
        //     if (floatSupply < assets) {
        //         floatLeg.mint(address(0), assets - floatSupply);
        //     }
        // }
        /*else */if (assets < liabilities/* + MIN_FLOAT_TV*/) {
            settleDebt();
        }
    }

    function settleDebt() internal {
        targetMul = (fixedLeg.totalSupply() * ONE / (potValue()/* - (MIN_FLOAT_TV)*/)) * ONE / rates.fixedValue(ONE);
    }

    /// @return Value in underlying of `amount` floatLeg tokens
    /// @dev By passing in `amount` we can multiply before dividing, saving precision
    /// @dev Require minimum total value to prevent totalSupply overflow
    /// @dev cant be public because some parameter valuse cause debt settlement
    function floatValue(uint amount, uint totalValue) public view returns (uint) {
        //if (floatLeg.totalSupply() == 0) {
        //    return amount;
        //}
        //require(totalValue > MIN_FLOAT_TV, "Protecting against potential totalSupply overflow");

        // add ONE to numerator and denominator to prevent float supply from growing too quickly
        return amount*(totalValue + ONE)/(floatLeg.totalSupply() + ONE);
    }

    /// @return Value in underlying of all floatLeg tokens
    function floatTotalValue(uint _fixedTotalNomValue) internal view returns (uint) {
        uint _potValue = potValue();
        if (_potValue > _fixedTotalNomValue) {
            return _potValue - _fixedTotalNomValue;
        }
        return 0;
    }

    /// @return Value in underlying of `amount` fixedLeg tokens
    function fixedValue(uint amount) internal view returns (uint) {
        uint value = rates.fixedValue(targetMul);
        // not neccesary because checkSolvency() is called beforehand
        //uint totalValue = fixedTotalNomValue(value);
        //uint _potValue = potValue();
        //if (_potValue < totalValue)
        //    return amount*_potValue/fixedLeg.totalSupply();
        return amount*ONE/value;
    }

    /// @return Nominal value in underlying of all fixedLeg tokens
    /// @param value Nominal value in underlying of 1 fixedLeg token
    function fixedTotalNomValue(uint value) internal view returns (uint) {
        return fixedLeg.totalSupply()*ONE/value;
    }

    function potValue() internal view returns (uint) {
        return underlying.balanceOf(address(this));
    }
}
