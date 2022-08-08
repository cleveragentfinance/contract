//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAgent {
    function initialized() external view returns (bool);
    function init(address[] memory, uint256[] memory) external;
    function totalValueLocked() external view returns (uint256);
    function availableDeposit(uint256) external view returns (uint256);
    function availableWithdraw(uint256) external view returns (uint256);
    function availableUnlock(uint256) external view returns (uint256);
    function availableHarvest() external view returns (uint256);
    function pendingReward() external view returns (uint256);
    function removable() external view returns (bool);
    function deposit() external;
    function withdraw(uint256) external;
    function unlockWithdraw(uint256) external;
    function harvest() external;
    function unlockHarvest() external;
    function depositToken() external view returns (address);
    function rewardToken() external view returns (address);
}