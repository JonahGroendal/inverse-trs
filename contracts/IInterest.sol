pragma solidity >=0.4.22 <0.9.0;

interface IInterest {
    function rate() external view returns (uint);
    function accrewedMul() external view returns (uint);
}
