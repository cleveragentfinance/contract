//       _                                           _   
//   ___| | _____   _____ _ __ __ _  __ _  ___ _ __ | |_ 
//  / __| |/ _ \ \ / / _ \ '__/ _` |/ _` |/ _ \ '_ \| __|
// | (__| |  __/\ V /  __/ | | (_| | (_| |  __/ | | | |_ 
//  \___|_|\___| \_/ \___|_|  \__,_|\__, |\___|_| |_|\__|
//                                  |___/                
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IStakingV2Controller {
    function stakeTokens(uint256 _amount, address _token) external payable;

    function proposeUnstake(uint256 _amount, address _token) external;

    function withdrawTokens(
        address payable _staker,
        uint256 _amount,
        address _token,
        uint256 _nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function unlockRewardsFromPoolsByController(
        address staker,
        address _to,
        address[] memory _tokenList
    ) external returns (uint256);

    function showRewardsFromPools(address[] memory _tokenList) external view returns (uint256);
    function stakersPoolV2() external view returns (address);
}

interface IStakersPoolV2 {
    function addStkAmount(address _token, uint256 _amount) external payable;

    function withdrawTokens(
        address payable _to,
        uint256 _amount,
        address _token,
        address _feePool,
        uint256 _fee
    ) external;

    function reCalcPoolPT(address _lpToken) external;

    function settlePendingRewards(address _account, address _lpToken) external;

    function harvestRewards(
        address _account,
        address _lpToken,
        address _to
    ) external returns (uint256);

    function getPoolRewardPerLPToken(address _lpToken) external view returns (uint256);

    function getStakedAmountPT(address _token) external view returns (uint256);

    function showPendingRewards(address _account, address _lpToken) external view returns (uint256);

    function showHarvestRewards(address _account, address _lpToken) external view returns (uint256);

    function getRewardToken() external view returns (address);

    function getRewardPerBlockPerPool(address _lpToken) external view returns (uint256);

    function claimPayout(
        address _fromToken,
        address _paymentToken,
        uint256 _settleAmtPT,
        address _claimToSettlementPool,
        uint256 _claimId,
        uint256 _fromRate,
        uint256 _toRate
    ) external;
}

interface IRewardController {
    function getRewardInfo() external view returns (uint256 r0, uint256 r1);
    function unlockReward(address[] memory _tokenList, bool _bBuyCoverUnlockedAmt, bool _bClaimUnlockedAmt, bool _bReferralUnlockedAmt) external;
    function withdrawReward(uint256 _pid) external;
}

interface ILPToken {
    function proposeToBurn(
        address _account,
        uint256 _amount,
        uint256 _blockWeight
    ) external;

    function mint(
        address _account,
        uint256 _amount,
        uint256 _poolRewardPerLPToken
    ) external;

    function rewardDebtOf(address _account) external view returns (uint256);

    function burnableAmtOf(address _account) external view returns (uint256);

    function burn(
        address _account,
        uint256 _amount,
        uint256 _poolRewardPerLPToken
    ) external;

    function pendingBurnAmtPH(address) external view returns (uint256);
}

contract InsurAceAgent is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    receive() external payable {}
    fallback() external payable {}
    address public manager;
    address public depositToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public receiveToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public rewardToken = 0x3192CCDdf1CDcE4Ff055EbC80f3F0231b86A7E30;
    address public lpToken = 0xDbbB520B40C7B7C6498dbD532AEE5e28c62b3611;
    address public sellRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public rewardController = 0x265aB8950821a4A4e8CED3C81905E4d4488DFC4c;
    address public target = 0xdEcAfc91000d4d3802A0562a8Fb896F29b6A7480;
    uint256 public minDepositAmount;
    bool public initialized;

    function init(address[] memory _addresses, uint256[] memory _values) public {
        require(initialized == false, "already initialized");
        manager = msg.sender;
        _transferOwnership(msg.sender);
        address[] memory addresses = _addresses;
        depositToken = addresses[0];
        receiveToken = addresses[1];
        rewardToken = addresses[2];
        target = addresses[3];
        lpToken = addresses[4];
        sellRouter = addresses[5];
        rewardController = addresses[6];
        minDepositAmount = _values[0];
    }

    function deposit() public onlyOwner {
        uint256 contractBalance = IERC20(receiveToken).balanceOf(address(this));
        if(receiveToken != depositToken) {
            address[] memory path = new address[](2);
            path[0] = receiveToken;
            path[1] = depositToken;
            IERC20(receiveToken).approve(sellRouter, contractBalance);
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(contractBalance, 0, path, address(this), block.timestamp);
        }
        uint256 depositAmount = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).approve(target, depositAmount);
        IStakingV2Controller(target).stakeTokens(depositAmount, depositToken);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        if(depositToken != receiveToken) {
            uint256 contractBalance = IERC20(depositToken).balanceOf(address(this));
            address[] memory path = new address[](2);
            path[0] = depositToken;
            path[1] = receiveToken;
            IERC20(depositToken).approve(sellRouter, contractBalance);
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(contractBalance, 0, path, address(this), block.timestamp);
        }
        uint256 balance = IERC20(receiveToken).balanceOf(address(this));
        uint256 available = _amount > balance ? balance : _amount;
        IERC20(receiveToken).transfer(manager, available);
    }

    function unlockWithdraw(uint256 _amount) public onlyOwner {
        IStakingV2Controller(target).proposeUnstake(_amount, depositToken);
    }

    function harvest() public onlyOwner {
        uint256 pending = ILPToken(lpToken).pendingBurnAmtPH(address(this));
        if(pending > 0) return;
        (uint256 vested,) = IRewardController(rewardController).getRewardInfo();
        if(vested < 1e15) return;
        uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));
        IRewardController(rewardController).withdrawReward(vested);
        uint256 claimed = IERC20(rewardToken).balanceOf(address(this)).sub(balanceBefore);
        address[] memory path = new address[](3);
        path[0] = rewardToken;
        path[1] = IUniswapV2Router01(sellRouter).WETH();
        path[2] = depositToken;
        IERC20(rewardToken).approve(sellRouter, claimed);
        IUniswapV2Router01(sellRouter).swapExactTokensForTokens(claimed, 0, path, manager, block.timestamp);
    }

    function unlockHarvest() public onlyOwner {
        address[] memory tokenList = new address[](1);
        tokenList[0] = depositToken;
        IRewardController(rewardController).unlockReward(tokenList, false, false, false);
    }

    function totalValueLocked() public view returns (uint256) {
        uint256 unlockable = availableHarvest();
        uint256 vesting = pendingReward();
        address[] memory path = new address[](3);
        path[0] = rewardToken;
        path[1] = IUniswapV2Router01(sellRouter).WETH();
        path[2] = depositToken;
        uint256[] memory amounts = IUniswapV2Router01(sellRouter).getAmountsOut(unlockable.add(vesting), path);
        address stakersV2 = IStakingV2Controller(target).stakersPoolV2();
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        uint256 totalStakedAmount = IStakersPoolV2(stakersV2).getStakedAmountPT(depositToken);
        uint256 depositedAmount = balance.mul(totalStakedAmount).div(IERC20(lpToken).totalSupply());
        return amounts[amounts.length - 1].add(depositedAmount);
    }

    function amount() public view returns (uint256) {
        address stakersV2 = IStakingV2Controller(target).stakersPoolV2();
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        uint256 totalStakedAmount = IStakersPoolV2(stakersV2).getStakedAmountPT(depositToken);
        uint256 depositedAmount = balance.mul(totalStakedAmount).div(IERC20(lpToken).totalSupply());
        return depositedAmount;
    }

    function availableDeposit(uint256 _amount) public view returns (uint256) {
        if(_amount < minDepositAmount) return 0;
        return type(uint256).max;
    }

    function availableWithdraw(uint256 _amount) public view returns (uint256) {
        uint256 available = IERC20(depositToken).balanceOf(address(this));
        if(depositToken != receiveToken)
            available += IERC20(receiveToken).balanceOf(address(this));
        return available > _amount ? _amount : available;
    }

    function availableUnlock(uint256) public view returns (uint256) {
        address stakersV2 = IStakingV2Controller(target).stakersPoolV2();
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        uint256 burnable = ILPToken(lpToken).burnableAmtOf(address(this));
        uint256 pending = ILPToken(lpToken).pendingBurnAmtPH(address(this));
        if(burnable > 0) return 0;
        uint256 totalStakedAmount = IStakersPoolV2(stakersV2).getStakedAmountPT(depositToken);
        uint256 available = balance.sub(pending).mul(totalStakedAmount).div(IERC20(lpToken).totalSupply());
        return available;
    }

    function availableHarvest() public view returns (uint256) {
        address[] memory tokenList = new address[](1);
        tokenList[0] = depositToken;
        return IStakingV2Controller(target).showRewardsFromPools(tokenList);
    }

    function pendingReward() public view returns (uint256) {
        (uint256 vested, uint256 pendingVest) = IRewardController(rewardController).getRewardInfo();
        return vested.add(pendingVest);
    }

    function removable() public pure returns (bool) {
        return false;
    }

}