// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IHurricaneSwapMasterChef.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPair.sol";
import "../lib/DexLibrary.sol";
import "./MasterChefStrategy.sol";

contract HurricaneSwapStrategyForLP is MasterChefStrategy {
    using SafeMath for uint256;

    IHurricaneSwapMasterChef public masterChef;
    IRouterEth public router;

    constructor(
        string memory _name,
        address _depositToken,
        address _rewardToken,
        address _router,
        address _stakingRewards,
        uint256 _pid,
        address _timelock,
        uint256 _minTokensToReinvest,
        uint256 _adminFeeBips,
        uint256 _devFeeBips,
        uint256 _reinvestRewardBips
    )
        Ownable()
        MasterChefStrategy(
            _name,
            _depositToken,
            _rewardToken,
            _stakingRewards,
            _timelock,
            _pid,
            _minTokensToReinvest,
            _adminFeeBips,
            _devFeeBips,
            _reinvestRewardBips
        )
    {
        masterChef = IHurricaneSwapMasterChef(_stakingRewards);
        router = IRouterEth(_router);
    }

    function _swapRewardTokenToDepositToken(uint256 _rewardTokenAmount)
        internal
        override
        returns (uint256 depositTokenAmount)
    {
        uint256 amountIn = _rewardTokenAmount.div(2);
        require(amountIn > 0, "DexStrategyV4::_convertRewardTokensToDepositTokens");

        // swap to token0
        uint256 path0Length = 2;
        address[] memory path0 = new address[](path0Length);
        path0[0] = address(rewardToken);
        path0[1] = IPair(address(depositToken)).token0();

        uint256 amountOutToken0 = amountIn;
        if (path0[0] != path0[path0Length - 1]) {
            uint256[] memory amountsOutToken0 = router.getAmountsOut(amountIn, path0);
            amountOutToken0 = amountsOutToken0[amountsOutToken0.length - 1];
            router.swapExactTokensForTokens(
                amountIn,
                amountOutToken0,
                path0,
                address(this),
                block.timestamp
            );
        }

        // swap to token1
        uint256 path1Length = 2;
        address[] memory path1 = new address[](path1Length);
        path1[0] = path0[0];
        path1[1] = IPair(address(depositToken)).token1();

        uint256 amountOutToken1 = amountIn;
        if (path1[0] != path1[path1Length - 1]) {
            uint256[] memory amountsOutToken1 = router.getAmountsOut(amountIn, path1);
            amountOutToken1 = amountsOutToken1[amountsOutToken1.length - 1];
            router.swapExactTokensForTokens(
                amountIn,
                amountOutToken1,
                path1,
                address(this),
                block.timestamp
            );
        }

        (, , depositTokenAmount) = router.addLiquidity(
            path0[path0Length - 1],
            path1[path1Length - 1],
            amountOutToken0,
            amountOutToken1,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _depositMasterchef(uint256 _pid, uint256 _amount) internal override {
        masterChef.deposit(_pid, _amount);
    }

    function _withdrawMasterchef(uint256 _pid, uint256 _amount) internal override {
        masterChef.withdraw(_pid, _amount);
    }

    function _emergencyWithdraw(uint256 _pid) internal override {
        masterChef.emergencyWithdraw(_pid);
    }

    function _pendingRewards(uint256 _pid, address _user)
        internal
        view
        override
        returns (uint256)
    {
        return masterChef.pending(_pid, _user);
    }

    function _getRewards(uint256 _pid) internal override {
        masterChef.deposit(_pid, 0);
    }

    function _userInfo(uint256 pid, address user)
        internal
        view
        override
        returns (uint256 amount, uint256 rewardDebt)
    {
        (amount, rewardDebt, ) = masterChef.userInfo(pid, user);
    }

    function _getDepositFeeBips(uint256 pid) internal view override returns (uint256) {
        return 0;
    }

    function _getWithdrawFeeBips(uint256 pid) internal view override returns (uint256) {
        return 0;
    }

    function _bip() internal view override returns (uint256) {
        return 10000;
    }
}
