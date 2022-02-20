pragma solidity ^0.8.11;

import "./IRates.sol";

contract MockRates is IRates {
    uint private _target = 1000*(10**18);

    function target() public view override returns (uint) {
        return _target;
    }

    function maxPriorityFee() public view override returns (uint) {
        return 3000000000;
    }


    function hedgeBuyPremium(uint amount) public view override returns (uint) {
        return 0;
    }
    function hedgeSellPremium(uint amount) public view override returns (uint) {
        return 0;
    }
    function leverageBuyPremium(uint amount) public view override returns (uint) {
        return 0;
    }
    function leverageSellPremium(uint amount) public view override returns (uint) {
        return 0;
    }

    function setTarget(uint t) public {
        _target = t;
    }
}