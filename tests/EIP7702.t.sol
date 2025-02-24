// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { Test, Vm, console } from "forge-std/src/Test.sol";
import { Empty } from "src/Empty.sol";
import { Owned } from "src/Owned.sol";
import { Proxy } from "src/Proxy.sol";
import { Wallet } from "src/Wallet.sol";
import { StorageDelegation } from "src/StorageDelegation.sol";

contract EIP7702Tests is Test {
    address payable ALICE_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant ALICE_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address constant BOB_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant BOB_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    Empty empty;
    Owned owned;
    Wallet walletV1;
    Wallet walletV2;
    Proxy proxy;
    StorageDelegation storageDelegation;

    function setUp() public virtual {
        empty = new Empty();
        owned = new Owned();
        walletV1 = new Wallet();
        walletV2 = new Wallet();
        proxy = new Proxy();
        storageDelegation = new StorageDelegation();

        deal(ALICE_ADDRESS, 10e18);
    }

    // Even with an empty contract, alice still has control over the EOA
    function test_eoa_ownership() external {
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(empty), ALICE_PK);
        vm.attachDelegation(signedDelegation);

        assertGt(ALICE_ADDRESS.code.length, 0);

        assertEq(BOB_ADDRESS.balance, 0);

        vm.prank(ALICE_ADDRESS);
        BOB_ADDRESS.call{ value: 1e18 }("");

        assertGt(BOB_ADDRESS.balance, 0);
    }

    // Using `address(this)`/EOA as the owner
    function test_owned() external {
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(owned), ALICE_PK);

        vm.attachDelegation(signedDelegation);

        assertGt(ALICE_ADDRESS.code.length, 0);

        assertEq(BOB_ADDRESS.balance, 0);

        vm.expectRevert("not-owner");
        Owned(ALICE_ADDRESS).sweep(BOB_ADDRESS);

        vm.prank(ALICE_ADDRESS);
        Owned(ALICE_ADDRESS).sweep(BOB_ADDRESS);

        assertGt(BOB_ADDRESS.balance, 0);
    }

    // Delegated contract can be a proxy
    function test_proxy() external {
        vm.startPrank(ALICE_ADDRESS);

        assertEq(ALICE_ADDRESS.code.length, 0);
        vm.signAndAttachDelegation(address(proxy), ALICE_PK);
        assertGt(ALICE_ADDRESS.code.length, 0);

        assertEq(Proxy(ALICE_ADDRESS).implementation(), address(0));
        Proxy(ALICE_ADDRESS).setImpl(address(walletV1));
        assertEq(Proxy(ALICE_ADDRESS).implementation(), address(walletV1));

        assertEq(BOB_ADDRESS.balance, 0);
        Wallet.Call[] memory calls = new Wallet.Call[](1);
        calls[0] = Wallet.Call({ data: "", to: BOB_ADDRESS, value: 1e18 });
        Wallet(ALICE_ADDRESS).execute(calls);
        assertGt(BOB_ADDRESS.balance, 0);

        assertEq(Wallet(ALICE_ADDRESS).numOfCalls(), 1);

        Proxy(ALICE_ADDRESS).setImpl(address(walletV2));
        assertEq(Proxy(ALICE_ADDRESS).implementation(), address(walletV2));

        assertEq(Wallet(ALICE_ADDRESS).numOfCalls(), 1);

        vm.stopPrank();
    }

    function test_storage() external {
        vm.signAndAttachDelegation(address(storageDelegation), ALICE_PK);

        StorageDelegation s = StorageDelegation(ALICE_ADDRESS);

        // same as proxy, constructor isn't executed during delegation
        assertEq(s.counter(), 0);

        uint256 VAL = 1;

        s.set(VAL);

        assertEq(s.counter(), VAL);

        // Revoking delegation doesn't clear the storage
        vm.signAndAttachDelegation(address(0), ALICE_PK);
        assertEq(vm.load(ALICE_ADDRESS, bytes32(uint256(0))), bytes32(VAL));
    }
}
