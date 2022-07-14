//       _                                           _   
//   ___| | _____   _____ _ __ __ _  __ _  ___ _ __ | |_ 
//  / __| |/ _ \ \ / / _ \ '__/ _` |/ _` |/ _ \ '_ \| __|
// | (__| |  __/\ V /  __/ | | (_| | (_| |  __/ | | | |_ 
//  \___|_|\___| \_/ \___|_|  \__,_|\__, |\___|_| |_|\__|
//                                  |___/                
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FreeToken is Ownable, ERC20("FREE", "Free Token"){
    address public lottery;

    constructor() {
        _mint(msg.sender, 1000000 * 1e18);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        if(spender != lottery)
            _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

}