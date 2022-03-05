pragma solidity >=0.4.22 <0.9.0;

interface IRates {
    /// @notice Gets target exchange rate of hedge from a price feed. Expressed as hedge per underlying
    function target() external view returns (uint);

    /// @notice Value of hedge in denominating currency. Changes based on the interest rate
    /// @return Target currency-hedge exchange rate, expressed as denominating currency per hedge
    function denomPerHedge() external view returns (uint);

    /// @notice Maximum allowed priority fee for trades
    /// @dev Prevents fruntrunning price oracle
    function maxPriorityFee() external view returns (uint);


    /// @return Fee required to buy `amount` hedge tokens
    /// @param value Value of trade in underlying
    function hedgeBuyPremium(uint value) external view returns (uint);

    /// @return Fee required to sell `amount` hedge tokens
    /// @param value Value of trade in underlying
    function hedgeSellPremium(uint value) external view returns (uint);

    /// @return Fee required to buy `amount` leverage tokens
    /// @param value Value of trade in underlying
    /// @param hedgeTotalValue Value in underlying of all hedge tokens
    /// @param leverageTotalValue Value in underlying of all leverage tokens
    function leverageBuyPremium(uint value, uint hedgeTotalValue, uint leverageTotalValue) external view returns (uint);

    /// @return Fee required to sell `amount` leverage tokens
    /// @param value Value of trade in underlying
    /// @param hedgeTotalValue Value in underlying of all hedge tokens
    /// @param leverageTotalValue Value in underlying of all leverage tokens
    function leverageSellPremium(uint value, uint hedgeTotalValue, uint leverageTotalValue) external view returns (uint);
}
