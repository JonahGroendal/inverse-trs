pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IToken.sol";

interface ISwap {
    function rates()      external returns (IRates);
    function fixedLeg()   external returns (IToken);
    function floatLeg()   external returns (IToken);
    function underlying() external returns (IToken);

    function buyFixed (uint amount, address to) external;
    function sellFixed(uint amount, address to) external;
    function buyFloat (uint amount, address to) external;
    function sellFloat(uint amount, address to) external;

    function floatValue(uint amount, uint totalValue) external view returns (uint);
    function floatTotalValue(uint _fixedTotalNomValue) external view returns (uint);
    function fixedValue(uint amount) external view returns (uint);
    function fixedTotalNomValue(uint value) external view returns (uint);
    function potValue() external view returns (uint);
}
