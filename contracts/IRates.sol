pragma solidity >=0.4.22 <0.9.0;

interface IRates {
    function interest() external view returns (uint);
    function fee() external view returns (uint);

    function fixedValueNominal(uint amount) external view returns (uint);
    function accIntMul() external view returns (uint);

    function setFee(uint _tolerance) external;
    function setPrice(address _price) external;
    function setModel(address _model) external;
}
