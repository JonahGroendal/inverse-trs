pragma solidity ^0.8.11;

import "./IRates.sol";
import "./IToken.sol";


/// @dev if collateralization ratio drops below 1, stablecoin holders can claim their share of the remaining collateral.
contract Swap {

    /// @notice minimum total value of leverage in underlying
    /// @dev prevents leverage `totalSupply` from growing too quickly and overflowing
    uint constant MIN_LEV_TOTAL_VALUE = 10**13;

    /// @notice Provides price of underlying in target asset
    IRates private rates;

    /// @notice The stablecoin. Value pegged to target asset
    IToken private hedge;

    /// @notice The unstablecoin. Gives leveraged exposure to underlying asset.
    IToken private leverage;

    /// @notice The token collateralizing hedge token / underlying leverage token
    IToken private underlying;

    struct DepositInfo {
        address account; // account doing the swap
        bool buy;        // was swap a buy or sell?
        bool hedge;      // was swap for hedge or leverage?
        uint timestamp;  // timestamp of swap block
        uint roundId;    // Chainlink roundId of price used for swap
        uint swapValue;  // swap value in underlying
        uint levRatio;   // leverage ratio of the token when it was bought or sold
    }
    mapping(bytes32 => uint) deposits; // keccak256(abi.encode(DepositInfo)) => deposit value

    uint totalDeposits;

    constructor(address _rates, address _hedge, address _leverage, address _underlying) {
        rates      = IRates(_rates);
        hedge      = IToken(_hedge);
        leverage   = IToken(_leverage);
        underlying = IToken(_underlying);
    }

    /// @notice Buy `amount` hedge tokens
    function buyHedge(uint amount) public returns (DepositInfo memory info)  {
        (uint value, uint roundId) = hedgeValue(amount);
        require(value > 0, "zero value");
        uint depositValue = rates.deposit(value, 10**18);
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.buyPremium(value, 10**18) + depositValue
        );
        hedge.mint(msg.sender, amount);
        if (depositValue > 0) {
            info = DepositInfo(
                msg.sender,
                true,   // buy
                true,   // hedge
                block.timestamp,
                roundId,
                value,
                10**18
            );
            deposits[keccak256(abi.encode(info))] += depositValue;
            totalDeposits += depositValue;
        }
    }

    /// @notice Sell `amount` hedge tokens
    function sellHedge(uint amount) public returns (DepositInfo memory info)  {
        (uint value, uint roundId) = hedgeValue(amount);
        require(value > 0, "zero value");
        uint depositValue = rates.deposit(value, 10**18);
        underlying.transfer(
            msg.sender,
            value - rates.sellPremium(value, 10**18) - depositValue
        );
        hedge.burnFrom(msg.sender, amount);
        if (depositValue > 0) {
            info = DepositInfo(
                msg.sender,
                false,  // sell
                true,   // hedge
                block.timestamp,
                roundId,
                value,
                10**18
            );
            deposits[keccak256(abi.encode(info))] += depositValue;
            totalDeposits += depositValue;
        }
    }

    /// @notice Buy `amount` leverage tokens
    function buyLeverage(uint amount) public returns (DepositInfo memory info)  {
        (uint value, uint roundId, uint levRatio) = leverageValue(amount);
        require(value > 0, "zero value");
        uint depositValue = rates.deposit(value, levRatio);
        underlying.transferFrom(
            msg.sender,
            address(this),
            value + rates.buyPremium(value, levRatio) + depositValue
        );
        leverage.mint(msg.sender, amount);
        if (depositValue > 0) {
            info = DepositInfo(
                msg.sender,
                true,  // buy
                false, // leverage
                block.timestamp,
                roundId,
                value,
                levRatio
            );
            deposits[keccak256(abi.encode(info))] += depositValue;
            totalDeposits += depositValue;
        }
    }

    /// @notice Sell `amount` leverage tokens
    function sellLeverage(uint amount) public returns (DepositInfo memory info) {
        (uint value, uint roundId, uint levRatio) = leverageValue(amount);
        require(value > 0, "zero value");
        uint premium = rates.sellPremium(value, levRatio);
        uint depositValue = rates.deposit(value, levRatio);
        if (depositValue > value - premium) {
            depositValue = value - premium; // cap deposit value
        }
        underlying.transfer(
            msg.sender,
            value - premium - depositValue
        );
        leverage.burnFrom(msg.sender, amount);
        if (depositValue > 0) {
            info = DepositInfo(
                msg.sender,
                false,  // sell
                false,  // leverage
                block.timestamp,
                roundId,
                value,
                levRatio
            );
            deposits[keccak256(abi.encode(info))] += depositValue;
            totalDeposits += depositValue;
        }
    }

    /// @notice Return the deposit for the swap minus any value realized within 30 seconds
    function reclaimDeposit(DepositInfo calldata info) public {
        // TODO: think through: what if collRatio is < 1 ?

        // buy  hedge + price increase = return deposit
        // buy  hedge + price decrease = take some deposit
        // sell hedge + price increase = take some deposit
        // sell hedge + price decrease = return deposit

        // buy  lev + price increase = take some deposit
        // buy  lev + price decrease = return deposit
        // sell lev + price increase = return deposit
        // sell lev + price decrease = take some deposit
        bytes32 index = keccak256(abi.encode(info));
        uint depositValue = deposits[index];

        uint priceAt = rates.targetAt(info.timestamp, info.roundId);
        uint priceAfter = rates.targetAfterDelay(info.timestamp, info.roundId);
        int priceChange = int(priceAfter) - int(priceAt);

        if (
            priceChange == 0 ||
            (priceChange > 0 && (( info.buy && info.hedge) || (!info.buy && !info.hedge))) ||
            (priceChange < 0 && ((!info.buy && info.hedge) || ( info.buy && !info.hedge)))
        ) {
            // only returning deposit value, there's no compensation for value lost
            underlying.transfer(info.account, depositValue);
        }
        else {
            if (priceChange < 0) {
                priceChange *= -1;
            }
            uint valueChange = uint(priceChange) * info.swapValue / priceAt;
            // multiply by leverage ratio
            valueChange = valueChange * info.levRatio / (10**18);
            if (valueChange < depositValue) {
                underlying.transfer(info.account, depositValue - valueChange);
            }
        }

        deposits[index] = 0;
        totalDeposits -= depositValue;
    }

    /// @return value Value of `amount` leverage tokens in underlying
    /// @return roundId Chainlink round ID used to calculate `value`
    /// @return levRatio Current leverage ratio of leverage tokens
    /// @dev Require minimum total value to prevent totalSupply overflow (still might be an issue idk)
    function leverageValue(uint amount) public view returns (uint value, uint roundId, uint levRatio) {
        uint totalValue;
        (totalValue, levRatio, roundId) = leverageTotalValue();
        if (leverage.totalSupply() == 0) {
            value = amount;
        } else {
            require(totalValue > 10**15, "protecting against potential totalSupply overflow");
            value = amount*totalValue/leverage.totalSupply();
        }
        
    }

    /// @return value Value in underlying of `amount` hedge tokens
    /// @return roundId of the Chainlink price used to calculate `value`
    function hedgeValue(uint amount) public view returns (uint value, uint roundId) {
        uint lastPrice;
        (lastPrice, roundId) = rates.target();
        uint totalNomValue = hedgeTotalNomValue(lastPrice);
        uint _potValue = underlying.balanceOf(address(this)) - totalDeposits;
        if (_potValue < totalNomValue) {
            value = amount*_potValue/hedge.totalSupply();
        }
        else {
            value = amount*(10**18)/lastPrice;
        }
    }

    /// @return totalValue Value in underlying of all leverage tokens
    /// @return levRatio Current leverage ratio of leverage tokens
    /// @return roundId Chainlink round ID of the price used to calculate `totalValue`
    function leverageTotalValue() internal view returns (uint totalValue, uint levRatio, uint roundId) {
        uint _hedgeTotalValue;
        uint _hedgeTotalNomValue;
        uint _potValue;
        (_hedgeTotalValue, _hedgeTotalNomValue, _potValue, roundId) = hedgeTotalValue();
        totalValue = _potValue - _hedgeTotalValue;
        if (totalValue == 0) {
            levRatio = _potValue * (10**18); // a really big number
        }
        else {
            levRatio = _potValue * (10**18) / totalValue;
        }
        // levRatio calculation above is the reduced form of:
        //uint collRatio = _potValue * (10**18) / _hedgeTotalNomValue;
        //levRatio = collRatio / (collRatio - (10**18));
    }

    /// @return totalValue Value in underlying of all hedge tokens
    /// @return totalNomValue Nominal value in underlying of all hedge tokens
    /// @return _potValue Value in underlying of all hedge tokens plus all leverage tokens
    /// @return roundId Chainlink round ID of the price used to calculate `totalValue`
    function hedgeTotalValue() internal view returns (uint totalValue, uint totalNomValue, uint _potValue, uint roundId) {
        uint lastPrice;
        (lastPrice, roundId) = rates.target();
        totalNomValue = hedgeTotalNomValue(lastPrice);
        _potValue = potValue();
        if (_potValue < totalNomValue)
            totalValue = _potValue;
        else
            totalValue = totalNomValue;
    }

    /// @return The nominal value of all hedge tokens
    function hedgeTotalNomValue(uint targetPrice) internal view returns (uint) {
        return hedge.totalSupply()*(10**18)/targetPrice;
    }

    /// @return The value of all hedge tokens plus all leverage tokens
    function potValue() internal view returns (uint) {
        return underlying.balanceOf(address(this)) - totalDeposits;
    }
}
