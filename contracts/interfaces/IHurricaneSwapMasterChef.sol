// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// https://cchain.explorer.avax.network/address/0x9984d70D5Ab32E8e552974A5A24661BFEfE81DbE/contracts
interface IHurricaneSwapMasterChef {
    function pending(uint256 pid, address user) external view returns (uint256);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function emergencyWithdraw(uint256 pid) external;
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt, uint256  multLpRewardDebt);
}