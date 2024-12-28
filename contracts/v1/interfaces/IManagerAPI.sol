// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

/// @title Interface for vault manager.
/// @notice Supports parameter submission.
interface IManagerAPI {
    /// @notice Initiate weight move to target in given update window.
    /// @dev These are checked by Balancer in internal transactions:
    ///       If target weight length and token length match.
    ///       If total sum of target weights is one.
    ///       If target weight is greater than minimum.
    /// @param targetWeights Target token weights.
    /// @param startTime Timestamp at which weight movement should start.
    /// @param endTime Timestamp at which the weights should reach target values.
    function updateWeightsGradually(
        uint256[] memory targetWeights,
        uint256 startTime,
        uint256 endTime
    ) external;

    /// @notice Cancel the active weight update schedule.
    /// @dev Keep calculated weights from the schedule at the time.
    function cancelWeightUpdates() external;

    /// @notice Change swap fee.
    /// @dev These are checked by Balancer in internal transactions:
    ///       If new swap fee is less than maximum.
    ///       If new swap fee is greater than minimum.
    function setSwapFee(uint256 newSwapFee) external;

    /// @notice Claim manager fee.
    function claimManagerFees() external;
}
