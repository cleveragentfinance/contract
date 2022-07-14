//       _                                           _   
//   ___| | _____   _____ _ __ __ _  __ _  ___ _ __ | |_ 
//  / __| |/ _ \ \ / / _ \ '__/ _` |/ _` |/ _ \ '_ \| __|
// | (__| |  __/\ V /  __/ | | (_| | (_| |  __/ | | | |_ 
//  \___|_|\___| \_/ \___|_|  \__,_|\__, |\___|_| |_|\__|
//                                  |___/                
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IAgentManager.sol";

contract Helper is Ownable {
    using SafeMath for uint256;
    IAgentManager public manager;

    constructor(IAgentManager _manager) {
        manager = _manager;
    }

    function getAvailableTicket(address _user) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 pid = 0; pid < manager.poolLength(); pid++) {
            IAgentManager.UserInfo memory user = manager.userInfo(pid, _user);
            uint256 multiplier = getMultiplier(user.lastUpdateTime, block.timestamp);
            uint256 reward = multiplier.mul(manager.apy()).mul(user.amount).div(1e18);
            total += user.accAmount;
            total += reward;
        }
        return total;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(manager.BONUS_MULTIPLIER());
    }

}
