// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "../dependencies/openzeppelin/IERC20.sol";
import "./IProtocolAPI.sol";
import "./IMultiAssetVault.sol";

/// @title Vault public interface.
/// @notice Interface for vault arbitrageurs and other observers.
interface IUserAPI {
    /// @notice Check if vault trading is enabled.
    /// @return If public swap is turned on, returns true, otherwise false.
    function isPublicSwap() external view returns (bool);

    /// @notice Get swap fee.
    /// @return Swap fee from underlying Balancer pool.
    function getSwapFee() external view returns (uint256);

    /// @notice Get Pool ID.
    /// @return Pool ID of Balancer pool on Vault.
    function getPoolId() external view returns (bytes32);

    /// @notice Get Token Data of Balancer Pool.
    /// @return tokens IERC20 tokens of Balancer pool.
    /// @return balances Balances of tokens of Balancer pool.
    /// @return lastChangeBlock Last updated Blocknumber.
    function getTokensData()
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /// @notice Get IERC20 Tokens Balancer Pool.
    /// @return tokens IERC20 tokens of Balancer pool.
    function getTokens() external view returns (IERC20[] memory);

    /// @notice Get token weight.
    /// @return Denormalized weight value from underlying Balancer pool.
    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);
}
