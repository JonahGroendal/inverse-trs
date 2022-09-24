pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IPrice.sol";
import "./IModel.sol";
import "./IToken.sol";

interface IParameters {
    function all() external view returns (uint, IModel, IPrice, IToken, IToken, IToken);
}