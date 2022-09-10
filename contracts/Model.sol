pragma solidity ^0.8.11;

import "./IModel.sol";

abstract contract Model is IModel {
    int constant ONE = 10**18;
    int constant STEP = ONE / 1000; // 0.1%
    int constant HALF_STEP = STEP / 2;

    function getInterestRate(uint potValue, uint fixedTV) external pure returns (int) {
        return((f(potValue, fixedTV) + HALF_STEP) / STEP) * STEP;
    }

    function f(uint potValue, uint fixedTV) internal virtual pure returns (int);
}

/// @notice Interest rate changes linearly wrt collateral ratio
contract LinearModel is Model {
    // y = Mx + B, where x is collateral ratio
    // there are 8765.82 hours in a year
    int constant M =  20 * ONE / 876582;
    int constant B = -28 * ONE / 876582;

    /// @notice M * collateral ratio + B
    /// @dev collateral ratio = pot value / fixed-leg total value
    function f(uint potValue, uint fixedTV) internal override pure returns (int) {
        unchecked {
            return ((M * int(potValue)) / int(fixedTV)) + B;
        }
    }
}

/// @notice Maintain a constant interest rate wrt value of float-leg tokens
contract ConstantFloatModel is Model {
    // there are 8765.82 hours in a year
    int constant FLOAT_RATE = 4 * ONE / 876582; // 4% APR, compounded hourly

    function f(uint potValue, uint fixedTV) internal override pure returns (int) {
        unchecked {
            return ((FLOAT_RATE * int(potValue)) / int(fixedTV)) - FLOAT_RATE;
        }
    }
}

/*
/// @notice Interest rate changes nonlinearly wrt collateral ratio
contract NonlinearModel is Model {
    // current idea:
    // (.001 / (x - 1)) + Mx + B
    // verticle asymtote at x = 1 and is about linear when x is larger
    // also a plus: interest rate wrt value of float-leg tokens is monotonically increasing with x
    // would need a minimum interest rate to avoid exploits
}
*/