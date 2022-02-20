pragma solidity >=0.4.22 <0.9.0;

abstract contract IRates {
    /// @notice Gets price of target in underlying from chainlink price feed
    function target() public view virtual returns (uint);

    function maxPriorityFee() public view virtual returns (uint);

    function hedgeBuyPremium(uint amount) public view virtual returns (uint);
    function hedgeSellPremium(uint amount) public view virtual returns (uint);
    function leverageBuyPremium(uint amount) public view virtual returns (uint);
    function leverageSellPremium(uint amount) public view virtual returns (uint);
}
