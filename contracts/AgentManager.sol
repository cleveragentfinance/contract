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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./interfaces/IAgent.sol";

interface IProxyAdmin {
    function upgrade(address, address) external;
}

contract AgentManager is Ownable {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 debt;
        uint256 pending;
        uint256 lastUpdateTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;
        uint256 balance;
        uint256 debt;
        uint256 accAmount;
        uint256 lastUpdateTime;
        uint256 totalEarned;
        uint256 autoTarget;
    }

    struct TargetInfo {
        address master;
        uint256 pid;
        address lpToken;
        address depositToken;
        address rewardToken;
        address[] initAddresses;
        uint256[] initNumbers;
    }

    struct DebtInfo {
        address owner;
        uint256 amount;
    }

    bool private initialized;

    uint256 public apy;
    uint256 public feePercent;
    address[] public routers = [0x10ED43C718714eb63d5aA57B78B54704E256024E];

    // Deposit Fee address
    address public feeAddress;
    address public lottery;
    address public proxyAdmin;
    address public freeToken;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each agent.
    TargetInfo[] public targetInfo;
    mapping (uint256 => address[]) public agents;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => DebtInfo[]) public debtInfo;
    // should be updated
    bool public autoTargetEnabled;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Compound(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event NewAgentCreated(uint256 indexed tid, address addr);

    function initialize(
        address _feeAddress,
        address _lottery,
        address _freeToken,
        uint256 _apy,
        uint256 _feePercent,
        address _proxyAdmin
    ) public {
        require(initialized == false, "already initialized");
        _transferOwnership(msg.sender);
        feeAddress = _feeAddress;
        lottery = _lottery;
        freeToken = _freeToken;
        apy = _apy;
        feePercent = _feePercent;
        proxyAdmin = _proxyAdmin;
    }

    function _createNewAgent(uint256 _tid, uint256 _amount) internal {
        TargetInfo memory target = targetInfo[_tid];
        bytes32 salt = keccak256(abi.encodePacked(target.master, block.number));
        bytes memory empty;
        TransparentUpgradeableProxy agent = new TransparentUpgradeableProxy{salt: salt}(target.master, address(this), empty);
        agent.changeAdmin(proxyAdmin);
        agents[_tid].push(address(agent));
        IAgent(address(agent)).init(target.initAddresses, target.initNumbers);
        uint256 available = IAgent(address(agent)).availableDeposit(_amount);
        available = available > _amount ? _amount : available;
        if(available > 0) {
            IERC20(target.depositToken).transfer(address(agent), available);
            IAgent(address(agent)).deposit();
        }
        emit NewAgentCreated(_tid, address(agent));
    }

    function _sendAssetToUser(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        DebtInfo[] storage debtList = debtInfo[_pid];
        uint256 contractBalance = pool.token.balanceOf(address(this));
        if(contractBalance < _amount) {
            pool.debt = pool.debt.add(_amount).sub(contractBalance);
            user.debt = user.debt.add(_amount).sub(contractBalance);
            debtList.push(DebtInfo({
                owner: msg.sender,
                amount: _amount.sub(contractBalance)
            }));
            pool.token.transfer(msg.sender, contractBalance);
        }
        else {
            pool.token.transfer(msg.sender, _amount);
        }
    }

    function _swap(uint256 _from, uint256 _to, uint256 _amount) internal returns (uint256) {
        if(_from == _to) return 0;
        PoolInfo storage from = poolInfo[_from];
        PoolInfo storage to = poolInfo[_to];
        require(from.balance >= _amount, "invalid amount");
        IUniswapV2Router01 router;
        uint256 amountOut;
        address[] memory path = new address[](2);
        path[0] = address(from.token);
        path[1] = address(to.token);
        for (uint256 index = 0; index < routers.length; index++) {
            uint256[] memory amounts = IUniswapV2Router01(routers[index]).getAmountsOut(_amount, path);
            if(amounts[amounts.length - 1] > amountOut) {
                amountOut = amounts[amounts.length - 1];
                router = IUniswapV2Router01(routers[index]);
            }
        }
        uint256 beforeBalance = to.token.balanceOf(address(this));
        from.token.approve(address(router), _amount);
        router.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return to.token.balanceOf(address(this)).sub(beforeBalance);
    }
    
    function _removeZeroList(uint256 _pid) internal {
        DebtInfo[] storage debtList = debtInfo[_pid];
        uint256 index = 0;
        while(index < debtList.length) {
            if(debtList[index].amount == 0) {
                for (uint256 j = index; j < debtList.length - 1; j++) {
                    debtList[j] = debtList[j + 1];
                }
                debtList.pop();
            }
            else index++;
        }
    }

    function _autoDeposit(uint256 _tid, uint256 depositAmount) internal {
        TargetInfo memory target = targetInfo[_tid];
        address[] storage agentList = agents[_tid];
        if(autoTargetEnabled && _tid > 0)
            depositAmount = IERC20(target.depositToken).balanceOf(address(this)).mul(9).div(10);
        uint256 j = 0;
        while(j < agentList.length && depositAmount > 0) {
            IAgent agent = IAgent(agentList[j]);
            uint256 available = agent.availableDeposit(depositAmount);
            if(available > 0) {
                available = available > depositAmount ? depositAmount : available;
                IERC20(target.depositToken).transfer(address(agent), available);
                agent.deposit();
                depositAmount = depositAmount.sub(available);
            }
            j++;
        }
        if(depositAmount > 0) {
            _createNewAgent(_tid, depositAmount);
        }
    }

    function updateUser(uint256 _pid, address _user) public {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pendingAmount = user.pending;
        if (block.timestamp > user.lastUpdateTime) {
            uint256 multiplier = getMultiplier(user.lastUpdateTime, block.timestamp);
            uint256 reward = multiplier.mul(apy).mul(user.amount).div(1e18);
            user.pending = pendingAmount.add(reward);
            IERC20(freeToken).transfer(_user, reward * 100);
            user.lastUpdateTime = block.timestamp;
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp > pool.lastUpdateTime) {
            uint256 multiplier = getMultiplier(pool.lastUpdateTime, block.timestamp);
            uint256 reward = multiplier.mul(apy).mul(pool.balance).div(1e18);
            pool.accAmount = (pool.accAmount).add(reward);
            pool.lastUpdateTime = block.timestamp;
        }
    }

    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }

    // Deposit LP tokens to MasterChef for Reward allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updateUser(_pid, msg.sender);
        updatePool(_pid);
        if(_amount > 0) {
            pool.token.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.balance = pool.balance.add(_amount);
        }
        if(autoTargetEnabled && poolInfo[_pid].autoTarget > 0) _autoDeposit(poolInfo[_pid].autoTarget, 0);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(pool.balance >= _amount, "withdraw: insufficient pool balance");
        updateUser(_pid, msg.sender);
        updatePool(_pid);
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.balance = pool.balance.sub(_amount);
            _sendAssetToUser(_pid, _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.amount > 0) {
            user.amount = 0;
            user.pending = 0;
            pool.balance = pool.balance.sub(user.amount);
            _sendAssetToUser(_pid, user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    function cancelPendingWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.debt = pool.debt.sub(user.debt);
        user.debt = 0;
        DebtInfo[] storage debtList = debtInfo[_pid];
        for (uint256 index = 0; index < debtList.length; index++) {
            if(debtList[index].owner == msg.sender) {
                user.amount += debtList[index].amount;
                pool.balance += debtList[index].amount;
                debtList[index].amount = 0;
            }
        }
        _removeZeroList(_pid);
    }

    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updateUser(_pid, msg.sender);
        pool.token.transfer(address(msg.sender), user.pending);
        user.pending = 0;
        emit Harvest(msg.sender, _pid, user.pending);
    }

    function harvestAll() public {
        for (uint256 tid = 0; tid < targetInfo.length; tid++) {
            TargetInfo memory target = targetInfo[tid];
            uint256 beforeBalance = IERC20(target.depositToken).balanceOf(address(this));
            address[] storage agentList = agents[tid];
            for (uint256 aid = 0; aid < agentList.length; aid++) {
                IAgent agent = IAgent(agentList[aid]);
                uint256 available = agent.availableHarvest();
                if(available > 0) {
                    agent.unlockHarvest();
                }
                agent.harvest();
            }
            uint256 earned = IERC20(target.depositToken).balanceOf(address(this)).sub(beforeBalance);
            if(earned > 0) {
                IERC20(target.depositToken).transfer(msg.sender, earned.div(20));
                earned = earned.mul(95).div(100);
                poolInfo[target.pid].totalEarned = poolInfo[target.pid].totalEarned.add(earned);
            }
        }

        // send user's debt
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][msg.sender];
            DebtInfo[] storage debtList = debtInfo[pid];
            for (uint256 index = 0; index < debtList.length; index++) {
                uint256 available = pool.token.balanceOf(address(this));
                DebtInfo storage debt = debtList[index];
                available = available > debtList[index].amount ? debt.amount : available;
                if(available == 0) break;
                pool.debt = pool.debt.sub(available, "sub: pool debt!");
                user.debt = user.debt.sub(available, "sub: user debt!");
                debt.amount = debt.amount.sub(available, "sub: debt!");
                pool.token.transfer(debt.owner, available);
            }
            _removeZeroList(pid);
        }

        massUpdatePools();
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _token) public onlyOwner {
        for (uint256 index = 0; index < poolInfo.length; index++) {
            require(poolInfo[index].token != _token, "duplicated pool");
        }
        poolInfo.push(PoolInfo({
            token: _token,
            balance: 0,
            debt: 0,
            accAmount: 0,
            lastUpdateTime: block.timestamp,
            totalEarned: 0,
            autoTarget: 0
        }));
    }

    function addTarget(address _master, address[] memory _initAddresses, uint256[] memory _initNumbers) public onlyOwner {
        uint256 pid;
        for (uint256 index = 0; index < poolInfo.length; index++) {
            if(address(poolInfo[index].token) == _initAddresses[1])
                pid = index;
        }
        targetInfo.push(TargetInfo({
            master: _master,
            pid: pid,
            lpToken: _initAddresses[0],
            depositToken: _initAddresses[1],
            rewardToken:  _initAddresses[2],
            initAddresses: _initAddresses,
            initNumbers: _initNumbers
        }));
    }

    // function updateTarget(uint256 _tid, address _master, address[] memory _initAddresses, uint256[] memory _initNumbers) public onlyOwner {
    //     uint256 pid;
    //     for (uint256 index = 0; index < poolInfo.length; index++) {
    //         if(address(poolInfo[index].token) == _initAddresses[1])
    //             pid = index;
    //     }
    //     TargetInfo memory target = targetInfo[_tid];
    //     target.master = _master;
    //     target.pid = pid;
    //     target.lpToken = _initAddresses[0];
    //     target.depositToken = _initAddresses[1];
    //     target.rewardToken =  _initAddresses[2];
    //     target.initAddresses = _initAddresses;
    //     target.initNumbers = _initNumbers;
    // }

    function UpdateAgents(uint256[] memory _tids, uint256[] memory _depositAmount, uint256[] memory _withdrawAmount, uint256[] memory _unlockAmount) public onlyOwner{
        for (uint256 i = 0; i < _tids.length; i++) {
            address[] storage agentList = agents[_tids[i]];
            uint256 j;
            // unlock
            if(_unlockAmount[i] > 0) {
                j = 0;
                while(j < agentList.length && _unlockAmount[i] > 0) {
                    IAgent agent = IAgent(agentList[j]);
                    uint256 available = agent.availableUnlock(_unlockAmount[i]);
                    if(available > 0) {
                        available = available > _unlockAmount[i] ? _unlockAmount[i] : available;
                        agent.unlockWithdraw(available);
                        _unlockAmount[i] = _unlockAmount[i].sub(available);
                    }
                    j++;
                }
            }
            // withdraw
            j = 0;
            while(j < agentList.length && _withdrawAmount[i] > 0) {
                IAgent agent = IAgent(agentList[j]);
                uint256 available = agent.availableWithdraw(_withdrawAmount[i]);
                if(available > 0) {
                    available = available > _withdrawAmount[i] ? _withdrawAmount[i] : available;
                    agent.withdraw(available);
                    _withdrawAmount[i] = _withdrawAmount[i].sub(available);
                }
                j++;
            }
            // deposit
            _autoDeposit(_tids[i], _depositAmount[i]);
            // remove blank agent
            j = 0;
            while(j < agentList.length) {
                IAgent agent = IAgent(agentList[j]);
                if(agent.removable()) {
                    agentList[j] = agentList[agentList.length - 1];
                    agentList.pop();
                }
                else
                    j++;
            }
        }
    }

    function updateAgentToNewContract(uint256 _tid, address _master) public onlyOwner{
        TargetInfo memory target = targetInfo[_tid];
        target.master = _master;
        address[] storage agentList = agents[_tid];
        for (uint256 aid = 0; aid < agentList.length; aid++) {
            IProxyAdmin(proxyAdmin).upgrade(agentList[aid], _master);
        }
    }

    function setAutoTarget(uint256 _pid, uint256 _tid) public onlyOwner {
        require(_pid < poolInfo.length, "invalid pid");
        require(_tid < targetInfo.length, "invalid tid");
        require(_tid > 0, "auto target should be bigger than 1");
        poolInfo[_pid].autoTarget = _tid;
    }

    function toggleAutoTarget() public onlyOwner {
        autoTargetEnabled = !autoTargetEnabled;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    function updateConfig(uint256 _apy, uint256 _feePercent, address _lottery, address[] memory _routers) public onlyOwner {
        require(_feePercent <= 10000, "can't exceeds 100%");
        apy = _apy;
        routers = _routers;
        feePercent = _feePercent;
        lottery = _lottery;
    }

    function distributeProfit() public onlyOwner {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            if(poolInfo[pid].totalEarned > poolInfo[pid].accAmount) {
                uint256 profit = poolInfo[pid].totalEarned - poolInfo[pid].accAmount;
                poolInfo[pid].token.transfer(feeAddress, profit.mul(feePercent).div(10000));
                uint256 amountOut = _swap(pid, 0, profit.mul(10000 - feePercent).div(10000));
                poolInfo[0].token.transfer(lottery, amountOut);
            }
        }
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function targetLength() public view returns (uint256) {
        return targetInfo.length;
    }
    
    function getAgentLength(uint256 _tid) public view returns (uint256) {
        return agents[_tid].length;
    }

    function getDebtInfoLength(uint256 _pid) public view returns (uint256) {
        return debtInfo[_pid].length;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending Rewards on frontend.
    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pendingAmount = user.pending;
        if (block.timestamp > user.lastUpdateTime) {
            uint256 multiplier = getMultiplier(user.lastUpdateTime, block.timestamp);
            uint256 reward = multiplier.mul(apy).mul(user.amount).div(1e18);
            pendingAmount = pendingAmount.add(reward);
        }
        return pendingAmount;
    }

    function getProtocolHealthRate() public view returns (uint256) {
        uint256 totalProfit;
        uint256 totalBalance;
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            totalBalance = totalBalance.add(pool.balance);
        }
        for (uint256 tid = 0; tid < targetInfo.length; tid++) {
            TargetInfo memory target = targetInfo[tid];
            totalProfit = totalProfit.add(IERC20(target.depositToken).balanceOf(address(this)));
            address[] storage agentList = agents[tid];
            for (uint256 aid = 0; aid < agentList.length; aid++) {
                IAgent agent = IAgent(agentList[aid]);
                totalProfit = totalProfit.add(agent.totalValueLocked());
            }
        }
        return totalProfit.mul(1e18).div(totalBalance);
    }

    function getTotalProfit() public view returns (uint256) {
        uint256 totalReward;
        uint256 totalProfit;
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            totalReward = totalReward.add(pool.accAmount).add(pool.balance);
            totalProfit = totalProfit.add(poolInfo[pid].totalEarned);
        }
        for (uint256 tid = 0; tid < targetInfo.length; tid++) {
            TargetInfo memory target = targetInfo[tid];
            totalProfit = totalProfit.add(IERC20(target.depositToken).balanceOf(address(this)));
            address[] storage agentList = agents[tid];
            for (uint256 aid = 0; aid < agentList.length; aid++) {
                IAgent agent = IAgent(agentList[aid]);
                totalProfit = totalProfit.add(agent.totalValueLocked());
            }
        }
        return totalProfit.sub(totalReward);
    }

}
