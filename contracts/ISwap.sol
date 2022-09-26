pragma solidity ^0.8.11;

import "./IToken.sol";

interface ISwap {
    function buyFixed (uint amount, address to) external;
    function sellFixed(uint amount, address to) external;
    function buyFloat (uint amount, address to) external;
    function sellFloat(uint amount, address to) external;

    function floatValue(uint amount) external view returns (uint);
    function fixedValue(uint amount) external view returns (uint, uint);
    function fixedValueNominal(uint amount) external view returns (uint);

    function updateInterestRate() external;

    function setParameters(address) external;
}
