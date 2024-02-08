// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../interfaces/binary/IERC20Mintable.sol";

contract RyzeToken is ERC20Burnable, AccessControl, IERC20Mintable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        require(isMinter(msg.sender), "ONLY_MINTER");
        _;
    }

    constructor() ERC20("Ryze Token", "RZT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address receipent, uint256 amount) external onlyMinter {
        _mint(receipent, amount);
    }

    /// @dev Return `true` if the account belongs to the user role.
    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }
}
