pragma solidity ^0.8.11;

import "./IToken.sol";

interface ISwap {
    function buyFloat  (uint amount, address to) external;
    function sellFloat (uint amount, address to) external;
    function buyEquity (uint amount, address to) external;
    function sellEquity(uint amount, address to) external;

    function equityValue(uint amount) external view returns (uint);
    function floatValue (uint amount) external view returns (uint, uint);
    function floatValueNominal(uint amount) external view returns (uint);

    function updateInterestRate() external;

    function setParameters(address) external;
}
