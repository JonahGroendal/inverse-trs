pragma solidity >=0.4.22 <0.9.0;

import "./IPrices.sol";

contract MockPrices is IPrices {
    uint private _target = 1000*10^18;

    function target() public view override returns (uint) {
        return _target;
    }
    function hedgeBuyPremium() public view override returns (uint) {
        return 0;
    }
    function hedgeSellPremium() public view override returns (uint) {
        return 0;
    }
    function leverageBuyPremium() public view override returns (uint) {
        return 0;
    }
    function leverageSellPremium() public view override returns (uint) {
        return 0;
    }

    function setTarget(uint t) public {
        _target = t;
    }
}