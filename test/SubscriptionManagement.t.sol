// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {SubscriptionManagement} from "src/SubscriptionManagement.sol";


//////////////////////////////
// Forge Tests
//////////////////////////////

// Tests for SubscriptionManagement
contract SubscriptionManagementTest is Test {
    SubscriptionManagement subscription;

    address owner = address(1);
    address nonOwner = address(2);
    address oracle = address(3);

    function setUp() public {
        vm.prank(owner);
        subscription = new SubscriptionManagement();
    }

    function testOnlyOwnerCanSetPrice() public {
        // Non-owner should revert.
        vm.prank(nonOwner);
        vm.expectRevert();
        subscription.setSubscriptionPrice(oracle, 1 ether);

        // Owner sets price successfully.
        vm.startPrank(owner);
        subscription.setSubscriptionPrice(oracle, 1 ether);
        uint256 price = subscription.subscriptionPrices(oracle);
        assertEq(price, 1 ether);
        vm.stopPrank();
    }

    function testPurchaseSubscriptionInsufficientPayment() public {
        vm.prank(owner);
        subscription.setSubscriptionPrice(oracle, 1 ether);

        // Attempt purchase with insufficient payment.
        vm.deal(nonOwner, 10 ether);
        vm.startPrank(nonOwner);
        uint year = subscription.ONE_YEAR();
        vm.expectRevert();
        subscription.purchaseSubscription{value: 0.5 ether}(oracle, year);
        vm.stopPrank();
    }

    function testPurchaseSubscriptionNewAndExtend() public {
        vm.prank(owner);
        subscription.setSubscriptionPrice(oracle, 1 ether);

        // First purchase: new subscription.
        uint256 startTime = block.timestamp;
        vm.startPrank(nonOwner);
        vm.deal(nonOwner, 10 ether);
        subscription.purchaseSubscription{value: 1 ether}(oracle, subscription.ONE_YEAR());
        uint256 expiry1 = subscription.subscriptions(oracle, nonOwner);
        assertGe(expiry1, startTime + subscription.ONE_YEAR());

        // Warp time forward by half a year.
        uint256 halfYear = subscription.ONE_YEAR() / 2;
        vm.warp(block.timestamp + halfYear);

        // Purchase again to extend subscription.
        subscription.purchaseSubscription{value: 0.5 ether}(oracle, halfYear);
        uint256 expiry2 = subscription.subscriptions(oracle, nonOwner);
        // Expect the expiry to be extended by halfYear.
        assertEq(expiry2, expiry1 + halfYear);
        vm.stopPrank();
    }

    function testIsActiveSubscription() public {
        vm.startPrank(owner);
        subscription.setSubscriptionPrice(oracle, 1 ether);

        // Before purchase, subscription is inactive.
        bool active = subscription.isActiveSubscription(nonOwner, oracle);
        assertFalse(active);

        // Purchase subscription.
        vm.startPrank(nonOwner);
        vm.deal(nonOwner, 10 ether);
        subscription.purchaseSubscription{value: 1 ether}(oracle, subscription.ONE_YEAR());
        active = subscription.isActiveSubscription(nonOwner, oracle);
        assertTrue(active);

        // Warp past expiry.
        vm.warp(block.timestamp + subscription.ONE_YEAR() + 1);
        active = subscription.isActiveSubscription(nonOwner, oracle);
        assertFalse(active);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.prank(owner);
        subscription.setSubscriptionPrice(oracle, 1 ether);

        // Purchase subscription so funds accumulate.
        vm.startPrank(nonOwner);
        vm.deal(nonOwner, 5 ether);
        subscription.purchaseSubscription{value: 1 ether}(oracle, subscription.ONE_YEAR());

        uint256 contractBalance = address(subscription).balance;
        assertEq(contractBalance, 1 ether);

        // Owner withdraws funds.
        uint256 ownerBalanceBefore = owner.balance;
        vm.startPrank(owner);
        subscription.withdraw();
        uint256 ownerBalanceAfter = owner.balance;
        // Confirm the owner's balance increased by the contract balance (ignoring gas).
        assertEq(ownerBalanceAfter, ownerBalanceBefore + 1 ether);
        vm.stopPrank();
    }
}

