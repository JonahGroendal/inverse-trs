pragma solidity >=0.4.22 <0.9.0;

abstract contract IPrices {
    /// @notice Gets price of target in underlying from chainlink price feed
    function target() public view virtual returns (uint);

    function hedgeBuyPremium() public view virtual returns (uint);
    function hedgeSellPremium() public view virtual returns (uint);
    function leverageBuyPremium() public view virtual returns (uint);
    function leverageSellPremium() public view virtual returns (uint);
}
