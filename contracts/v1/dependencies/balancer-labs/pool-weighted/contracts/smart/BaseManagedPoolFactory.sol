// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../../../pool-utils/contracts/factories/BasePoolSplitCodeFactory.sol";
import "../../../pool-utils/contracts/factories/FactoryWidePauseWindow.sol";

import "../../../standalone-utils/contracts/AumProtocolFeesCollector.sol";

import "./ManagedPool.sol";

/**
 * @dev This is a base factory designed to be called from other factories to deploy a ManagedPool
 * with a particular controller/owner. It should NOT be used directly to deploy ManagedPools without
 * controllers. ManagedPools controlled by EOAs would be very dangerous for LPs. There are no restrictions
 * on what the managers can do, so a malicious manager could easily manipulate prices and drain the pool.
 *
 * In this design, other controller-specific factories will deploy a pool controller, then call this factory to
 * deploy the pool, passing in the controller as the owner.
 */
contract BaseManagedPoolFactory is BasePoolSplitCodeFactory, FactoryWidePauseWindow {
    AumProtocolFeesCollector private immutable _aumProtocolFeesCollector;

    constructor(IVault vault) BasePoolSplitCodeFactory(vault, type(ManagedPool).creationCode) {
        _aumProtocolFeesCollector = new AumProtocolFeesCollector(vault);
    }

    /**
     * @dev Getter for the AUM protocol fees collector passed into all Managed Pools created from this factory.
     */
    function getAumProtocolFeesCollector() external view returns (AumProtocolFeesCollector) {
        return _aumProtocolFeesCollector;
    }

    /**
     * @dev Deploys a new `ManagedPool`. The owner should be a managed pool controller, deployed by
     * another factory.
     */
    function create(ManagedPool.NewPoolParams memory poolParams, address owner) external returns (address pool) {
        (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) = getPauseConfiguration();

        return
            _create(
                abi.encode(
                    ManagedPool.NewPoolParams({
                        name: poolParams.name,
                        symbol: poolParams.symbol,
                        tokens: poolParams.tokens,
                        normalizedWeights: poolParams.normalizedWeights,
                        assetManagers: poolParams.assetManagers,
                        swapFeePercentage: poolParams.swapFeePercentage,
                        swapEnabledOnStart: poolParams.swapEnabledOnStart,
                        mustAllowlistLPs: poolParams.mustAllowlistLPs,
                        protocolSwapFeePercentage: poolParams.protocolSwapFeePercentage,
                        managementSwapFeePercentage: poolParams.managementSwapFeePercentage,
                        managementAumFeePercentage: poolParams.managementAumFeePercentage,
                        aumProtocolFeesCollector: _aumProtocolFeesCollector
                    }),
                    getVault(),
                    owner,
                    pauseWindowDuration,
                    bufferPeriodDuration
                )
            );
    }
}
