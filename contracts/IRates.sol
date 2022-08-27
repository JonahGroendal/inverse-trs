pragma solidity >=0.4.22 <0.9.0;

interface IRates {
    function interest() external view returns (uint);
    function maxPriorityFee() external view returns (uint);

    function fixedValue() external view returns (uint);
    function accIntMul() external view returns (uint);

    function fixedBuyPremium(uint value) external view returns (uint);
    function fixedSellPremium(uint value) external view returns (uint);
    function floatBuyPremium(uint value, uint fixedTotalValue, uint floatTotalValue) external view returns (uint);
    function floatSellPremium(uint value, uint fixedTotalValue, uint floatTotalValue) external view returns (uint);

    function setInterest(uint _interest) external;
    function setMaxPriorityFee(uint _maxPriorityFee) external;
    function setTolerance(uint _tolerance) external;
    function setPriceFeed(address _priceFeed) external;
}
