pragma solidity ^0.8.11;

interface IPrice {
    function get() external view returns (uint);
}