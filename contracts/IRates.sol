pragma solidity >=0.4.22 <0.9.0;

interface IRates {
    function fixedValue(uint multiplier) external view returns (uint);

    function accIntMul() external view returns (uint);

    function maxPriorityFee() external view returns (uint);
    function setMaxPriorityFee(uint _maxPriorityFee) external;

    function fixedBuyPremium(uint value) external view returns (uint);
    function fixedSellPremium(uint value) external view returns (uint);
    function floatBuyPremium(uint value, uint fixedTotalValue, uint floatTotalValue) external view returns (uint);
    function floatSellPremium(uint value, uint fixedTotalValue, uint floatTotalValue) external view returns (uint);
}
