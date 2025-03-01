// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {SubscriptionManagement} from "src/SubscriptionManagement.sol";
import {EACAggregatorProxy} from "src/EACAggregatorProxy.sol";
import {MockAggregator} from "test/mocks/MockAggregator.sol";

// Tests for EACAggregatorProxy
contract EACAggregatorProxyTest is Test {
    SubscriptionManagement subscription;
    MockAggregator mockAgg;
    EACAggregatorProxy proxyPublicFree;
    EACAggregatorProxy proxyPublicSubscribable;
    EACAggregatorProxy proxyPrivate;

    address owner = address(1);
    address subscriber = address(2);
    address nonSubscriber = address(3);
    address aggregatorAddress;

    function setUp() public {
        // Deploy SubscriptionManagement.
        vm.startPrank(owner);
        subscription = new SubscriptionManagement();

        // Deploy MockAggregator.
        mockAgg = new MockAggregator();
        aggregatorAddress = address(mockAgg);

        // Deploy proxies in each mode.
        // PublicFree: no restrictions.
        proxyPublicFree = new EACAggregatorProxy(aggregatorAddress, address(subscription), EACAggregatorProxy.OracleType.PublicFree);
        // PublicSubscribable: requires active subscription.
        proxyPublicSubscribable = new EACAggregatorProxy(aggregatorAddress, address(subscription), EACAggregatorProxy.OracleType.PublicSubscribable);
        // Private: requires whitelisting.
        proxyPrivate = new EACAggregatorProxy(aggregatorAddress, address(subscription), EACAggregatorProxy.OracleType.Private);
        vm.stopPrank();
    }

    function testPublicFreeAccess() public {
        // Any caller can call latestAnswer.
        int256 answer = proxyPublicFree.latestAnswer();
        assertEq(answer, 100);
    }

    function testPublicSubscribableAccessWithoutSubscription() public {
        // Caller without subscription should revert.
        vm.prank(nonSubscriber);
        vm.expectRevert(EACAggregatorProxy.NotSubscribed.selector);
        proxyPublicSubscribable.latestAnswer();
    }

    function testPublicSubscribableAccessWithSubscription() public {
        // Set a subscription price and have subscriber purchase.
        vm.prank(owner);
        subscription.setSubscriptionPrice(address(proxyPublicSubscribable), 1 ether);
        
        vm.startPrank(subscriber);
        vm.deal(subscriber, 10 ether);
        subscription.purchaseSubscription{value: 1 ether}(address(proxyPublicSubscribable), subscription.ONE_YEAR());

        // Now subscriber should access the proxy.
        
        int256 answer = proxyPublicSubscribable.latestAnswer();
        assertEq(answer, 100);
        vm.stopPrank();
    }

    function testPublicSubscribableAccessWithSubscriptionAndRefund() public {
      // Set a subscription price and have subscriber purchase.
      vm.prank(owner);
      subscription.setSubscriptionPrice(address(proxyPublicSubscribable), 1 ether);
      
      vm.startPrank(subscriber);
      vm.deal(subscriber, 10 ether);
      uint256 balanceBefore = subscriber.balance;
      
      // Subscriber sends 5 ether while only 1 ether is required.
      subscription.purchaseSubscription{value: 5 ether}(address(proxyPublicSubscribable), subscription.ONE_YEAR());

      // Now subscriber should access the proxy.
      int256 answer = proxyPublicSubscribable.latestAnswer();
      assertEq(answer, 100);

      // Check that the subscriber received a refund of the overpayment (allowing slight gas deduction).
      // Expected refund: 5 ether sent - 1 ether cost = 4 ether refund, so balance should be close to initial minus 1 ether.
      uint256 balanceAfter = subscriber.balance;
      assertGe(balanceAfter, balanceBefore - 1 ether - 1); // Allowing for minor gas costs.

      vm.stopPrank();
    }

    function testPrivateAccessWithoutWhitelist() public {
        vm.prank(nonSubscriber);
        vm.expectRevert(EACAggregatorProxy.NotWhitelisted.selector);
        proxyPrivate.latestAnswer();
    }

    function testPrivateAccessWithWhitelist() public {
        // Whitelist the nonSubscriber.
        vm.startPrank(owner);
        proxyPrivate.addToWhitelist(nonSubscriber);
        vm.stopPrank();

        vm.prank(nonSubscriber);
        int256 answer = proxyPrivate.latestAnswer();
        assertEq(answer, 100);
    }
}
