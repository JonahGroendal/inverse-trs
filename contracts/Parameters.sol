pragma solidity ^0.8.11;

import "./IParameters.sol";

contract Parameters is IParameters {
    /// @notice Fee rate applied to notional value of trade.
    /// @notice Prevents soft frontrunning.
    /// @dev 18-decimal fixed-point
    uint immutable fee;

    /// @notice Interest rate model
    IModel immutable model;

    /// @notice Price of underlying in target asset
    IPrice immutable price;

    /// @notice Tokens comprising the swap's fixed leg
    /// @notice Pegged to denominating asset + accrewed interest
    /// @dev Must use 18 decimals
    IToken immutable fixedLeg;

    /// @notice Tokens comprising the swap's floating leg
    /// @notice Pegged to [R/(R-1)]x leveraged underlying
    /// @dev Must use 18 decimals
    IToken immutable floatLeg;

    /// @notice Token collateralizing fixedLeg / underlying floatLeg
    /// @dev Must use 18 decimals
    IToken immutable underlying;

    constructor(
        uint _fee,
        IModel _model,
        IPrice _price,
        IToken _fixedLeg,
        IToken _floatLeg,
        IToken _underlying)
    {
        fee        = _fee;
        model      = _model;
        price      = _price;
        fixedLeg   = _fixedLeg;
        floatLeg   = _floatLeg;
        underlying = _underlying;
    }

    function get() public view returns (uint, IModel, IPrice, IToken, IToken, IToken) {
        return (fee, model, price, fixedLeg, floatLeg, underlying);
    }
}