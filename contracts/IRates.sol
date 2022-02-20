pragma solidity >=0.4.22 <0.9.0;

abstract contract IRates {
    /// @notice Gets price of target in underlying from chainlink price feed
    function target() public view virtual returns (uint price, uint roundId);

    /// @return what the target price was at the given timestamp
    /// @param roundId roundId to start looking for the timestamp
    function targetAt(uint timestamp, uint roundId) public view virtual returns (uint);

    /// @return what the target price was some seconds after the given timestamp
    /// @param roundId roundId to start looking for the timestamp
    function targetAfterDelay(uint timestamp, uint roundId) public view virtual returns (uint);

    function buyPremium(uint amount, uint levRatio) public view virtual returns (uint);
    function sellPremium(uint amount, uint levRatio) public view virtual returns (uint);

    /// @return required deposit for a buy or sell of a given value at a given collateralization ratio
    /// @dev `levRatio` can be very large, will need to cap return value if it's too big
    function deposit(uint value, uint levRatio) public view virtual returns (uint);
}
