pragma solidity ^0.8.11;

import "./IPrice.sol";
import "./IModel.sol";
import "./IToken.sol";

interface IParameters {
    function get() external view returns (uint, IModel, IPrice, IToken, IToken, IToken);
}