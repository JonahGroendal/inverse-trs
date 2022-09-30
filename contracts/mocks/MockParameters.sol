pragma solidity ^0.8.0;

import "../IParameters.sol";

contract MockParameters is IParameters {
    uint private fee;

    IModel immutable model;

    IPrice immutable price;

    IToken immutable hedge;

    IToken immutable leverage;

    IToken immutable underlying;

    constructor(
        uint _fee,
        IModel _model,
        IPrice _price,
        IToken _hedge,
        IToken _leverage,
        IToken _underlying)
    {
        fee        = _fee;
        model      = _model;
        price      = _price;
        hedge      = _hedge;
        leverage   = _leverage;
        underlying = _underlying;
    }

    function get() public view returns (uint, IModel, IPrice, IToken, IToken, IToken) {
        return (fee, model, price, hedge, leverage, underlying);
    }

    function setFee(uint _fee) public {
        fee = _fee;
    }
}