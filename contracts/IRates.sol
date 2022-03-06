pragma solidity >=0.4.22 <0.9.0;

interface IRates {
    /// @notice The target fixed-underlying exchange rate.
    /// @notice Gets exchange rate of underlying from a price feed. Expressed as fixed per underlying
    function target() external view returns (uint);

    /// @notice Value of fixed in denominating currency. Changes based on the interest rate
    /// @return Target currency-fixed exchange rate, expressed as denominating currency per fixed
    function denomPerFixed() external view returns (uint);

    /// @notice Maximum allowed priority fee for trades
    /// @dev Prevents fruntrunning price oracle
    function maxPriorityFee() external view returns (uint);


    /// @return Fee required to buy `amount` fixed tokens
    /// @param value Value of trade in underlying
    function fixedBuyPremium(uint value) external view returns (uint);

    /// @return Fee required to sell `amount` fixed tokens
    /// @param value Value of trade in underlying
    function fixedSellPremium(uint value) external view returns (uint);

    /// @return Fee required to buy `amount` float tokens
    /// @param value Value of trade in underlying
    /// @param fixedTotalValue Value in underlying of all fixed tokens
    /// @param floatTotalValue Value in underlying of all float tokens
    function floatBuyPremium(uint value, uint fixedTotalValue, uint floatTotalValue) external view returns (uint);

    /// @return Fee required to sell `amount` float tokens
    /// @param value Value of trade in underlying
    /// @param fixedTotalValue Value in underlying of all fixed tokens
    /// @param floatTotalValue Value in underlying of all float tokens
    function floatSellPremium(uint value, uint fixedTotalValue, uint floatTotalValue) external view returns (uint);
}
