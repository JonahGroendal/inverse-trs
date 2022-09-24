pragma solidity ^0.8.11;

import "../IParameters.sol";

contract MockParameters is IParameters {
    uint private fee;

    IModel immutable model;

    IPrice immutable price;

    IToken immutable fixedLeg;

    IToken immutable floatLeg;

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

    function all() public view returns (uint, IModel, IPrice, IToken, IToken, IToken) {
        return (fee, model, price, fixedLeg, floatLeg, underlying);
    }

    function setFee(uint _fee) public {
        fee = _fee;
    }
}