pragma solidity ^0.8.11;

interface IModel {
    function getInterestRate(uint potValue, uint fixedTV) external view returns (int);
}