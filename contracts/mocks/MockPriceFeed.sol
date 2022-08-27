pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockPriceFeed is AggregatorV3Interface {
    int256 internal price = (10**18) * 1000;

    function latestRoundData() public view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, price, 1, 1, 1);
    }

    function setPrice(int256 _price) public {
        price = _price;
    }



    /*
     * unused functions implemented to comply with interface
     */

    function decimals() external view returns (uint8) {
        return 18;
    }

    function description() external view returns (string memory) {
        return "blahblahblah";
    }

    function version() external view returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (1, 1, 1, 1, 1);
    }
}
