//       _                                           _     __   _____ 
//      | |                                         | |   /  | |  _  |
//   ___| | _____   _____ _ __ __ _  __ _  ___ _ __ | |_  `| | | |/' |
//  / __| |/ _ \ \ / / _ \ '__/ _` |/ _` |/ _ \ '_ \| __|  | | |  /| |
// | (__| |  __/\ V /  __/ | | (_| | (_| |  __/ | | | |_  _| |_\ |_/ /
//  \___|_|\___| \_/ \___|_|  \__,_|\__, |\___|_| |_|\__| \___(_)___/ 
//                                   __/ |                            
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

interface IVault {
    function deposit(address _token, uint256 _amount, bool _claimRewards) external;
    function withdraw(address _token, uint256 _amount, bool _claimRewards) external;
    function userInfo(address _token, address _user) external view returns (uint256, uint256, uint256, uint256);
    function emergencyWithdraw(address _token) external;
    function claimableReward(address _user, address[] memory _tokens) external view returns (uint256[] memory);
    function claim(address _user, address[] memory _tokens) external;    
}

interface IEllipsisRouter {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external;
}

interface ILPToken {
    function getReward() external;
}

contract Ellipsis is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    receive() external payable {}
    fallback() external payable {}
    address public manager;
    address public depositToken = 0x73A7A74627f5A4fcD6d7EEF8E023865C4a84CfE8;
    address public receiveToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public rewardToken = 0xAf41054C1487b0e5E2B9250C0332eCBCe6CE9d71;
    address public target = 0x5B74C99AA2356B4eAa7B85dC486843eDff8Dfdbe;
    address public lpRouter = 0x4d9508257Af7442827951f30dbFe3ee2a04ADCeE;
    address public sellRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public token0 = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint256 public totalDepositedAmount;
    bool public initialized;

    function init(address[] memory _addresses, uint256[] memory _values) public {
        require(initialized == false, "already initialized");
        manager = msg.sender;
        _transferOwnership(msg.sender);
        address[] memory addresses = _addresses;
        depositToken = addresses[0];
        receiveToken = addresses[1];
        rewardToken = addresses[2];
        sellRouter = addresses[3];
        target = 0x5B74C99AA2356B4eAa7B85dC486843eDff8Dfdbe;
        lpRouter = 0x4d9508257Af7442827951f30dbFe3ee2a04ADCeE;
        token0 = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        initialized = true;
    }

    function deposit() public onlyOwner {
        uint256 contractBalance = IERC20(receiveToken).balanceOf(address(this));
        totalDepositedAmount += contractBalance;
        address[] memory path = new address[](2);
        if(receiveToken != token0) {
            path[0] = receiveToken;
            path[1] = token0;
            IERC20(receiveToken).approve(sellRouter, contractBalance);
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(contractBalance, 0, path, address(this), block.timestamp);
        }
        uint256[2] memory amounts;
        amounts[0] = 0;
        amounts[1] = IERC20(token0).balanceOf(address(this));
        IERC20(token0).approve(lpRouter, amounts[1]);
        IEllipsisRouter(lpRouter).add_liquidity(amounts, 0);
        uint256 depositAmount = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).approve(target, depositAmount);
        IVault(target).deposit(depositToken, depositAmount, true);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        (uint256 lockedAmount,,,) = IVault(target).userInfo(depositToken, address(this));
        uint256 availableAmount = _amount > lockedAmount ? lockedAmount : _amount;
        IVault(target).withdraw(depositToken, availableAmount, true);
        uint256 contractBalance = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).approve(lpRouter, contractBalance);
        IEllipsisRouter(lpRouter).remove_liquidity_one_coin(contractBalance, 1, 0);
        if(receiveToken != token0) {
            uint256 available = IERC20(token0).balanceOf(address(this));
            address[] memory path = new address[](2);
            path[0] = token0;
            path[1] = receiveToken;
            IERC20(token0).approve(sellRouter, available);
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(available, 0, path, address(this), block.timestamp);
        }
        uint256 balance = IERC20(receiveToken).balanceOf(address(this));
        totalDepositedAmount -= totalDepositedAmount.mul(availableAmount).div(lockedAmount);
        IERC20(receiveToken).transfer(manager, balance);
    }

    function unlockWithdraw(uint256 _amount) public view onlyOwner {
        return;
    }

    function harvest() public onlyOwner {
        address[] memory tokens = new address[](1);
        tokens[0] = depositToken;
        IVault(target).claim(address(this), tokens);
        ILPToken(depositToken).getReward();
        address[] memory path = new address[](3);
        path[0] = rewardToken;
        path[1] = IUniswapV2Router01(sellRouter).WETH();
        path[2] = receiveToken;
        uint256 sellAmount = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).approve(sellRouter, sellAmount);
        IUniswapV2Router01(sellRouter).swapExactTokensForTokens(sellAmount, 0, path, address(this), block.timestamp);
        path[0] = 0x7c1608C004F20c3520f70b924E2BfeF092dA0043;
        path[1] = IUniswapV2Router01(sellRouter).WETH();
        path[2] = receiveToken;
        sellAmount = IERC20(0x7c1608C004F20c3520f70b924E2BfeF092dA0043).balanceOf(address(this));
        IERC20(0x7c1608C004F20c3520f70b924E2BfeF092dA0043).approve(sellRouter, sellAmount);
        IUniswapV2Router01(sellRouter).swapExactTokensForTokens(sellAmount, 0, path, address(this), block.timestamp);
        IERC20(receiveToken).transfer(manager, IERC20(receiveToken).balanceOf(address(this)));
    }

    function unlockHarvest() public view onlyOwner {
        return;
    }

    function totalValueLocked() public view returns (uint256) {
        (uint256 lockedAmount,,,) = IVault(target).userInfo(depositToken, address(this));
        uint256 depositedAmount;
        address[] memory path = new address[](2);
        uint256[] memory amounts;
        if(receiveToken != token0) {
            path[0] = token0;
            path[1] = receiveToken;
            amounts = IUniswapV2Router01(sellRouter).getAmountsOut(lockedAmount, path);
            depositedAmount += amounts[amounts.length - 1];
        }
        else
            depositedAmount += lockedAmount;
        uint256 reward = pendingReward();
        path = new address[](3);
        path[0] = rewardToken;
        path[1] = IUniswapV2Router01(sellRouter).WETH();
        path[2] = receiveToken;
        amounts = IUniswapV2Router01(sellRouter).getAmountsOut(reward, path);
        depositedAmount += amounts[amounts.length - 1];
        return depositedAmount;
    }

    function amount() public view returns (uint256, uint256, uint256) {
        (uint256 lockedAmount,,,) = IVault(target).userInfo(depositToken, address(this));
        return (totalDepositedAmount, 0, lockedAmount);
    }

    function availableDeposit(uint256 _amount) public pure returns (uint256) {
        return type(uint128).max;
    }

    function availableWithdraw(uint256 _amount) public pure returns (uint256) {
        return type(uint128).max;
    }

    function availableUnlock(uint256) public pure returns (uint256) {
        return 0;
    }

    function availableHarvest() public pure returns (uint256) {
        return 0;
    }

    function pendingReward() public view returns (uint256) {
        address[] memory tokens = new address[](1);
        tokens[0] = depositToken;
        uint256[] memory amounts = IVault(target).claimableReward(address(this), tokens);
        return amounts[0];
    }

    function removable() public pure returns (bool) {
        return false;
    }

    function unlockTimeLeft() public pure returns (uint256) {
        return 0;
    }

}