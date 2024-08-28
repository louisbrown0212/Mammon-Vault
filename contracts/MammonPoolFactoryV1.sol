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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./dependencies/balancer-labs/vault/contracts/interfaces/IVault.sol";

import "./dependencies/balancer-labs/pool-utils/contracts/factories/BasePoolSplitCodeFactory.sol";
import "./dependencies/balancer-labs/pool-utils/contracts/factories/FactoryWidePauseWindow.sol";

import "./dependencies/balancer-labs/pool-weighted/contracts/smart/ManagedPool.sol";

contract MammonPoolFactoryV1 is
    BasePoolSplitCodeFactory,
    FactoryWidePauseWindow
{
    constructor(IVault vault)
        BasePoolSplitCodeFactory(vault, type(ManagedPool).creationCode)
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @notice Deploys a New Balancer ManagedPool.
    /// @param name Pool Token name.
    /// @param symbol Pool Token symbol.
    /// @param tokens Addresses of asset tokens.
    /// @param weights Initial weights of asset tokens.
    /// @param assetManagers Addresses of asset managers.
    /// @param swapFeePercentage Swap fee percentage.
    /// @param owner Pool controller.
    /// @param swapEnabledOnStart Swap enabled states on start.
    /// @param mustAllowlistLPs If true, only listed addresses can join the pool.
    /// @param managementSwapFeePercentage Management swap fee percentage.
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory weights,
        address[] memory assetManagers,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart,
        bool mustAllowlistLPs,
        uint256 managementSwapFeePercentage
    ) external returns (address) {
        (
            uint256 pauseWindowDuration,
            uint256 bufferPeriodDuration
        ) = getPauseConfiguration();

        return
            _create(
                abi.encode(
                    ManagedPool.NewPoolParams({
                        vault: getVault(),
                        name: name,
                        symbol: symbol,
                        tokens: tokens,
                        normalizedWeights: weights,
                        assetManagers: assetManagers,
                        swapFeePercentage: swapFeePercentage,
                        pauseWindowDuration: pauseWindowDuration,
                        bufferPeriodDuration: bufferPeriodDuration,
                        owner: owner,
                        swapEnabledOnStart: swapEnabledOnStart,
                        mustAllowlistLPs: mustAllowlistLPs,
                        managementSwapFeePercentage: managementSwapFeePercentage
                    })
                )
            );
    }
}
