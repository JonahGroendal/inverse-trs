pragma solidity >=0.4.22 <0.9.0;

import "./IRatesBasic.sol";

contract MockRatesBasic is IRatesBasic {
    uint private _target = 1000*(10**18);

    function target() public view override returns (uint) {
        return _target;
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

