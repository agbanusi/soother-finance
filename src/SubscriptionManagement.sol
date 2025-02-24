// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SubscriptionManagement {
    address public owner;
    uint256 public constant ONE_YEAR = 31536000; // One year in seconds

    // Mapping: oracle address => subscriber address => subscription expiry timestamp.
    mapping(address => mapping(address => uint256)) public subscriptions;
    
    // Mapping: oracle address => subscription price for one-year (in wei)
    mapping(address => uint256) public subscriptionPrices;

    event SubscriptionPurchased(address indexed subscriber, address indexed oracle, uint256 expiryTime);
    event SubscriptionPriceSet(address indexed oracle, uint256 price);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    /**
     * @notice Set the subscription price for a specific oracle.
     * @param oracle The address of the oracle contract.
     * @param price The price (in wei) for a one-year subscription.
     */
    function setSubscriptionPrice(address oracle, uint256 price) external onlyOwner {
        subscriptionPrices[oracle] = price;
        emit SubscriptionPriceSet(oracle, price);
    }

    /**
     * @notice Purchase or extend a subscription for a specific oracle.
     * @param oracle The address of the oracle contract.
     *
     * Requirements:
     * - The oracle must have a subscription price set.
     * - msg.value must be at least the subscription price.
     *
     * If the subscriber already has an active subscription, the expiry is extended.
     */
    function purchaseSubscription(address oracle, uint256 _duration) external payable {
        uint256 price = subscriptionPrices[oracle] * _duration / ONE_YEAR;
        require(price > 0, "Subscription not available for this oracle");
        require(msg.value >= price, "Insufficient payment");

        // If subscription is active, extend; otherwise, start from current time.
        uint256 currentExpiry = subscriptions[oracle][msg.sender];
        if (currentExpiry < block.timestamp) {
            currentExpiry = block.timestamp;
        }
        subscriptions[oracle][msg.sender] = currentExpiry + _duration;
        emit SubscriptionPurchased(msg.sender, oracle, subscriptions[oracle][msg.sender]);
    }

    /**
     * @notice Check if a subscriber's subscription for a specific oracle is active.
     * @param subscriber The address of the subscriber.
     * @param oracle The address of the oracle contract.
     * @return True if active, false otherwise.
     */
    function isActiveSubscription(address subscriber, address oracle) external view returns (bool) {
        return subscriptions[oracle][subscriber] >= block.timestamp;
    }
    
    /**
     * @notice Withdraw collected funds.
     */
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
