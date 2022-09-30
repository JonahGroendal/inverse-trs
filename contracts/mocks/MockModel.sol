pragma solidity ^0.8.0;

import "../IModel.sol";

contract MockModel is IModel {
    int private interest;

    function getInterestRate(uint potValue, uint hedgeTV) external override view returns (int) {
        return interest;
    }

    function setInterest(int _interest) public {
        interest = _interest;
    }
}