// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

import "./interfaces/IBFactory.sol";
import "./interfaces/IBPool.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/balancer-labs/configurable-rights-pool/blob/master/libraries/SmartPoolManager.sol";

contract MammonBalancerPrivatePoolVault is Ownable {
    uint private constant ONE = 10**18;
    uint private constant MIN_CONVERGENCE_SPEED = 10**12;
    uint private constant BASE_WEIGHT = ONE * 5;

    IBFactory private bFactory;
    IBPool private bPool;

    address public immutable token0;
    address public immutable token1;
    uint private convergenceSpeed;
    uint private targetShare2;
    bool private initialized;
    SmartPoolManager.GradualUpdateParams private gradualUpdate;

    constructor (address factory, address _token0, address _token1) {
        bFactory = IBFactory(factory);
        bPool = bFactory.newBPool();
        token0 = _token0;
        token1 = _token1;
    }

    function init(
        uint256[] memory amounts,
        uint256[] memory weights
    )
        external
        onlyOwner
    {
        require (!initialized, "already initialized");
        require (amounts.length == 2, "need amounts for two tokens");
        require (weights.length == 2, "need weights for two tokens");

        // Transfer token0 to this contract
        IERC20(token0).transferFrom(msg.sender, address(this), amounts[0]);
        // Approve the balancer pool
        IERC20(token0).approve(address(bPool), type(uint).max);
        // Bind token0
        bPool.bind(token0, amounts[0], weights[0]);

        // Transfer token1 to this contract
        IERC20(token1).transferFrom(msg.sender, address(this), amounts[1]);
        // Approve the balancer pool
        IERC20(token1).approve(address(bPool), type(uint).max);
        // Bind token1
        bPool.bind(token1, amounts[1], weights[1]);

        gradualUpdate.startWeights = weights;
        initialized = true;
    }

    function deposit(uint[] memory amounts) external onlyOwner {
        // Deposit each amount of tokens
        require (amounts.length == 2, "need amounts for two tokens");

        address[2] memory tokens = [token0, token1];

        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint tokenBalance = getBalance(tokens[i]);
            uint tokenDenorm = getDenormalizedWeight(tokens[i]);

            uint newBalance = tokenBalance + amounts[i];
            uint newDenorm = tokenDenorm * newBalance / tokenBalance;

            if (newBalance > tokenBalance) {
                uint needBalance = newBalance - tokenBalance;
                require (
                    token.transferFrom(msg.sender, address(this), needBalance),
                    "deposit: transferFrom failed"
                );
            }

            if (token.allowance(address(this), address(bPool)) != type(uint).max) {
                token.approve(address(bPool), type(uint).max);
            }

            bPool.rebind(tokens[i], newBalance, newDenorm);
        }
    }

    function withdraw(uint[] memory amounts) external onlyOwner {
        // Withdraw as much as possible up to each amount of tokens
        require (amounts.length == 2, "need amounts for two tokens");

        address[2] memory tokens = [token0, token1];

        for (uint i = 0; i < tokens.length; i++) {
            uint tokenBalance = getBalance(tokens[i]);
            uint tokenDenorm = getDenormalizedWeight(tokens[i]);

            require (tokenBalance >= amounts[i], "low balance");

            uint newBalance = tokenBalance - amounts[i];
            uint newDenorm = tokenDenorm * newBalance / tokenBalance;

            bPool.rebind(tokens[i], newBalance, newDenorm);

            IERC20 token = IERC20(tokens[i]);
            require (
                token.transfer(msg.sender, token.balanceOf(address(this))),
                "withdraw: transferFrom failed"
            );
        }
    }

    function gulp(address token) external onlyOwner {
        bPool.gulp(token);
    }

    function updateWeightsGradually(uint[] memory newWeights)
        public
        onlyOwner
    {
        // Library computes the startBlock,
        // computes startWeights as the current
        // denormalized weights of the core pool tokens.
        require (newWeights.length == 2, "need new weights for two tokens");

        uint endBlock = getExpectedFinalBlock();

        SmartPoolManager.updateWeightsGradually(
            bPool,
            gradualUpdate,
            newWeights,
            block.number,
            endBlock,
            0
        );
    }

    function pokeWeights() external onlyOwner {
        SmartPoolManager.pokeWeights(bPool, gradualUpdate);
    }

    function setTargetShare2(uint newTargetShare2) external onlyOwner {
        // Set target share for token2 and call updateWeightsGradually
        require (
            newTargetShare2 <= ONE,
            "targetShare2 mustn't be greater than 1"
        );

        uint w1;
        uint w2;

        if (newTargetShare2 == ONE) {
            w2 = BASE_WEIGHT;
        } else if (newTargetShare2 == 0) {
            w1 = BASE_WEIGHT;
        } else {
            w1 = BASE_WEIGHT;
            w2 = w1 * newTargetShare2 / (ONE - newTargetShare2);
        }

        targetShare2 = newTargetShare2;

        uint[] memory newWeights = new uint[](2);
        newWeights[0] = w1;
        newWeights[1] = w2;

        updateWeightsGradually(newWeights);
    }

    function setConvergenceSpeed(uint newSpeed) external onlyOwner {
        convergenceSpeed = newSpeed;
    }

    function setPublicSwap(bool value) external onlyOwner {
        bPool.setPublicSwap(value);
    }

    function setSwapFee(uint newSwapFee) external onlyOwner {
        bPool.setSwapFee(newSwapFee);
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    function isPublicSwap() public view returns (bool) {
        return bPool.isPublicSwap();
    }

    function getBFactory() public view returns (IBFactory) {
        return bFactory;
    }

    function getBPool() public view returns (IBPool) {
        return bPool;
    }

    function getCurrentShare2() public view returns (uint) {
        uint w1 = getDenormalizedWeight(token0);
        uint w2 = getDenormalizedWeight(token1);

        return w2 * ONE / (w1 + w2);
    }

    function getConvergenceSpeed() public view returns (uint) {
        return convergenceSpeed;
    }

    function getSwapFee() external view returns (uint) {
        return bPool.getSwapFee();
    }

    function getExpectedFinalBlock() public view returns (uint) {
        return block.number + ONE / convergenceSpeed;
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        public
        view
        returns (uint)
    {
        return bPool.getSpotPrice(tokenIn, tokenOut);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        public
        view
        returns (uint)
    {
        return bPool.getSpotPriceSansFee(tokenIn, tokenOut);
    }

    function getBalance(address token) public view returns (uint) {
        return bPool.getBalance(token);
    }

    function getDenormalizedWeight(address token) public view returns (uint) {
        return bPool.getDenormalizedWeight(token);
    }

    function totalSupply() external view returns (uint) {
        return bPool.totalSupply();
    }
}