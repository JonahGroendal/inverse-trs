
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Token is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory _name, string memory _symbol, address admin) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}


// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.2;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// contract Token is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
//     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
//     bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() initializer {}

//     function initialize(string _name, string _symbol) initializer public {
//         __ERC20_init(_name, _symbol);
//         __ERC20Burnable_init();
//         __AccessControl_init();
//         __UUPSUpgradeable_init();

//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _grantRole(MINTER_ROLE, msg.sender);
//         _grantRole(UPGRADER_ROLE, msg.sender);
//     }

//     function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
//         _mint(to, amount);
//     }

//     function _authorizeUpgrade(address newImplementation)
//         internal
//         onlyRole(UPGRADER_ROLE)
//         override
//     {}
// }
