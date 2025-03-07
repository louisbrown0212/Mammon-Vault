// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../v1/dependencies/openzeppelin/Ownable.sol";
import "../v1/dependencies/openzeppelin/Create2.sol";
import "./ManagerWhitelist.sol";

/// @title Factory to deploy ManagerWhitelist contract.
contract ManagerWhitelistFactory is Ownable {
    /// EVENTS ///

    /// @notice Emitted when a new ManagerWhitelist is deployed.
    /// @param addr Deployed address of ManagerWhitelist.
    /// @param salt Used salt value for deployment.
    event Deployed(address indexed addr, uint256 salt);

    /// FUNCTIONS ///

    // solhint-disable no-empty-blocks
    constructor(address owner) {
        _transferOwnership(owner);
    }

    /// @notice Deploy ManagerWhitelist contract
    /// @param managers Initial manager addresses.
    /// @param salt Salt value to be used for deployment.
    function deploy(address[] calldata managers, uint256 salt)
        external
        onlyOwner
    {
        ManagerWhitelist managerWhitelist = new ManagerWhitelist{
            salt: bytes32(salt)
        }(managers);
        managerWhitelist.transferOwnership(msg.sender);

        // slither-disable-next-line reentrancy-events
        emit Deployed(address(managerWhitelist), salt);
    }

    /// @notice Returns precomputed address
    /// @dev Returns the address where a contract will be stored if deployed via {deploy}.
    ///     Any change in the `bytecodeHash` or `salt` will result in a new destination address.
    /// @param managers Initial manager addresses.
    /// @param salt Salt value to be used for deployment.
    /// @return Precomputed address of ManagerWhitelist deployment.
    // slither-disable-next-line too-many-digits
    function computeAddress(address[] calldata managers, uint256 salt)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(ManagerWhitelist).creationCode,
                abi.encode(managers)
            )
        );

        address addr = Create2.computeAddress(
            bytes32(salt),
            bytecodeHash,
            address(this)
        );

        return addr;
    }
}
