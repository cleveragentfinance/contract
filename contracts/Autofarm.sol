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

interface IUniswapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IVault {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);

    function emergencyWithdraw(uint256 _pid) external;
}
contract Autofarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    receive() external payable {}
    fallback() external payable {}
    address public manager;
    address public depositToken = 0x1483767E665B3591677Fd49F724bf7430C18Bf83;
    address public receiveToken = 0x55d398326f99059fF775485246999027B3197955;
    address public rewardToken = 0x55d398326f99059fF775485246999027B3197955;
    address public target = 0x0895196562C7868C5Be92459FaE7f877ED450452;
    address public lpRouter = 0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8;
    address public sellRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint256 public pid;
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
        target = addresses[3];
        lpRouter = addresses[4];
        sellRouter = addresses[5];
        pid = _values[0];
        initialized = true;
    }

    function deposit() public onlyOwner {
        uint256 contractBalance = IERC20(receiveToken).balanceOf(address(this));
        totalDepositedAmount += contractBalance;
        address token0 = IUniswapPair(depositToken).token0();
        address token1 = IUniswapPair(depositToken).token1();
        address[] memory path = new address[](2);
        if(receiveToken != token0) {
            path[0] = receiveToken;
            path[1] = token0;
            IERC20(receiveToken).approve(sellRouter, contractBalance.div(2));
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(contractBalance.div(2), 0, path, address(this), block.timestamp);
        }
        if(receiveToken != token1) {
            path[0] = receiveToken;
            path[1] = token1;
            IERC20(receiveToken).approve(sellRouter, contractBalance.div(2));
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(contractBalance.div(2), 0, path, address(this), block.timestamp);
        }
        path[0] = token0;
        path[1] = token1;
        IERC20(token0).approve(lpRouter, IERC20(token0).balanceOf(address(this)));
        IERC20(token1).approve(lpRouter, IERC20(token1).balanceOf(address(this)));
        IUniswapV2Router01(lpRouter).addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
        uint256 depositAmount = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).approve(target, depositAmount);
        IVault(target).deposit(pid, depositAmount);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        address token0 = IUniswapPair(depositToken).token0();
        address token1 = IUniswapPair(depositToken).token1();
        uint256 lockedAmount = IVault(target).stakedWantTokens(pid, address(this));
        uint256 availableAmount = _amount > lockedAmount ? lockedAmount : _amount;
        IVault(target).withdraw(pid, availableAmount);
        uint256 contractBalance = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).approve(lpRouter, contractBalance);
        IUniswapV2Router01(lpRouter).removeLiquidity(token0, token1, contractBalance, 0, 0, address(this), block.timestamp);
        if(receiveToken != token0) {
            uint256 available = IERC20(token0).balanceOf(address(this));
            address[] memory path = new address[](2);
            path[0] = token0;
            path[1] = receiveToken;
            IERC20(token0).approve(sellRouter, available);
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(available, 0, path, address(this), block.timestamp);
        }
        if(receiveToken != token1) {
            uint256 available = IERC20(token1).balanceOf(address(this));
            address[] memory path = new address[](2);
            path[0] = token1;
            path[1] = receiveToken;
            IERC20(token1).approve(sellRouter, available);
            IUniswapV2Router01(sellRouter).swapExactTokensForTokens(available, 0, path, address(this), block.timestamp);
        }
        uint256 balance = IERC20(receiveToken).balanceOf(address(this));
        IERC20(receiveToken).transfer(manager, balance);
        totalDepositedAmount -= totalDepositedAmount.mul(availableAmount).div(lockedAmount);
    }

    function unlockWithdraw(uint256 _amount) public view onlyOwner {
        return;
    }

    function harvest() public view onlyOwner {
        return;
    }

    function unlockHarvest() public view onlyOwner {
        return;
    }

    function totalValueLocked() public view returns (uint256) {
        uint256 lockedAmount = IVault(target).stakedWantTokens(pid, address(this));
        address token0 = IUniswapPair(depositToken).token0();
        address token1 = IUniswapPair(depositToken).token1();
        uint256 lpSupply = IUniswapPair(depositToken).totalSupply();
        uint256 share0 = IERC20(token0).balanceOf(depositToken).mul(lockedAmount).div(lpSupply) + IERC20(token0).balanceOf(address(this));
        uint256 share1 = IERC20(token1).balanceOf(depositToken).mul(lockedAmount).div(lpSupply) + IERC20(token1).balanceOf(address(this));
        uint256 depositedAmount;
        address[] memory path = new address[](2);
        if(receiveToken != token0) {
            path[0] = token0;
            path[1] = receiveToken;
            uint256[] memory amounts = IUniswapV2Router01(sellRouter).getAmountsOut(share0, path);
            depositedAmount += amounts[amounts.length - 1];
        }
        else
            depositedAmount += share0;
        if(receiveToken != token1) {
            path[0] = token1;
            path[1] = receiveToken;
            uint256[] memory amounts = IUniswapV2Router01(sellRouter).getAmountsOut(share1, path);
            depositedAmount += amounts[amounts.length - 1];
        }
        else
            depositedAmount += share1;
        return depositedAmount;
    }

    function amount() public view returns (uint256, uint256, uint256) {
        return (totalDepositedAmount, 0, totalDepositedAmount);
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
        uint256 tvl = totalValueLocked();
        if(tvl < totalDepositedAmount) return 0;
        return tvl - totalDepositedAmount;
    }

    function removable() public pure returns (bool) {
        return false;
    }

    function unlockTimeLeft() public pure returns (uint256) {
        return 0;
    }

}