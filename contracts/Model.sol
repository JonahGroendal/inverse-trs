pragma solidity ^0.8.11;

import "./IModel.sol";

abstract contract Model is IModel {
    int constant ONE = 10**18;
    int constant STEP = ONE / 8765820; // 0.1% annually, compounded hourly

    function getInterestRate(uint potValue, uint hedgeTV) external pure returns (int) {
        return(f(potValue, hedgeTV) / STEP) * STEP;
    }

    function f(uint potValue, uint hedgeTV) internal virtual pure returns (int);
}

/// @notice Interest rate changes linearly wrt collateral ratio
contract LinearModel is Model {
    // y = Mx + B, where x is collateral ratio
    // there are 8765.82 hours in a year
    int constant M =  20 * ONE / 876582;
    int constant B = -28 * ONE / 876582;

    /// @notice M * collateral ratio + B
    /// @dev collateral ratio = pot value / hedge total value
    function f(uint potValue, uint hedgeTV) internal override pure returns (int) {
        if (hedgeTV == 0) {
            return 0;
        }
        unchecked {
            return ((M * int(potValue)) / int(hedgeTV)) + B;
        }
    }
}

/// @notice Maintain a constant interest rate wrt value of leverage tokens
contract ConstantFloatModel is Model {
    // there are 8765.82 hours in a year
    int constant FLOAT_RATE = 4 * ONE / 876582; // 4% APR, compounded hourly

    function f(uint potValue, uint hedgeTV) internal override pure returns (int) {
        if (hedgeTV == 0) {
            return 0;
        }
        unchecked {
            return ((FLOAT_RATE * int(potValue)) / int(hedgeTV)) - FLOAT_RATE;
        }
    }
}

/*
/// @notice Interest rate changes nonlinearly wrt collateral ratio
contract NonlinearModel is Model {
    // current idea:
    // (.001 / (x - 1)) + Mx + B
    // verticle asymtote at x = 1 and is about linear when x is larger
    // also a plus: interest rate wrt value of leverage tokens is monotonically increasing with x
    // would need a minimum interest rate to avoid exploits
}
*/