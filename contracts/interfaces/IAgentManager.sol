// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgentManager {
    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 debt;
        uint256 pending;
        uint256 accAmount;
        uint256 lastUpdateTime;
    }

    // Info of each pool.
    struct PoolInfo {
        address token;
        uint256 balance;
        uint256 debt;
        uint256 accAmount;
        uint256 lastUpdateTime;
        uint256 totalEarned;
        uint256 totalPayed;
    }

    struct TargetInfo {
        address master;
        uint256 pid;
        address depositToken;
        address rewardToken;
        address[] initAddresses;
        uint256[] initNumbers;
    }

    struct DebtInfo {
        address owner;
        uint256 amount;
    }

    function owner() external view returns (address);
    function buyTicket(address _user, uint256 _amount) external returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256) external view returns (PoolInfo memory);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function apy() external view returns (uint256);
    function BONUS_MULTIPLIER() external view returns (uint256);
}