pragma solidity ^0.8.11;

import "../IPrice.sol";

contract MockPrice is IPrice {
    int256 internal price = (10**18) * 1000;

    function get() external view returns (uint) {
        return uint(price);
    }

    function setPrice(int256 _price) public {
        price = _price;
    }
}