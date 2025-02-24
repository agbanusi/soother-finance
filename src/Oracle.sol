// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {AggregatorProxy} from "./chainlink/EACAggregatorProxy.sol";

/// @notice Minimal interface for subscription management
interface ISubscriptionManagement {
    function isActiveSubscription(address subscriber, address oracle) external view returns (bool);
}

contract SootherOracle is AggregatorProxy {
    // Oracle types.
    enum OracleType {
        PublicSubscribable, // Requires active subscription.
        PublicFree,         // Free to use; gas cost paid by partners.
        Private             // Only whitelisted addresses can update.
    }

    OracleType public oracleType;

    // External subscription management contract.
    ISubscriptionManagement public subscriptionContract;

    // For private oracles: whitelisted addresses.
    mapping(address => bool) public whitelist;

    // Custom errors for gas efficiency.
    error Unauthorized();
    error NotSubscribed();
    error NotWhitelisted();
    error InvalidOracleType();

    event PriceUpdated(int256 newPrice, uint256 roundId, uint256 timestamp);

    /**
     * @notice Constructor.
     * @param _oracleType The type of oracle.
     * @param _subscriptionContract Address of the subscription management contract.
     */
    constructor(
        address _aggregator,
        address _subscriptionContract,
        OracleType _oracleType
    ) AggregatorProxy(_aggregator) {
        oracleType = _oracleType;
        subscriptionContract = ISubscriptionManagement(_subscriptionContract);
    }


    /**
     * @notice Add an address to the whitelist (for private oracles).
     * @param _addr Address to whitelist.
     */
    function addToWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;
    }

    /**
     * @notice Remove an address from the whitelist.
     * @param _addr Address to remove.
     */
    function removeFromWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = false;
    }

    // /**
    //  * @notice Update the oracle price. This function is designed to be gas efficient.
    //  * @param _newPrice The new aggregated price.
    //  */
    // function updatePrice(int256 _newPrice) external onlyOwner {
    //     // Minimal state update for gas efficiency.
    //     latestAnswer = _newPrice;
    //     latestTimestamp = block.timestamp;
    //     roundId++;

    //     emit PriceUpdated(_newPrice, roundId, block.timestamp);
    // }

    /**
     * @notice Provides the latest round data in a Chainlink-compatible format.
     * Requirements:
     * - For PublicSubscribable: Caller must have an active subscription (checked by the subscription management contract).
     * - For Private: Caller must be whitelisted.
     * - For PublicFree: No additional checks.
     */
    function latestRoundData()
        public
        view
        virtual
        override
        returns (
            uint80 roundId_,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        if (oracleType == OracleType.PublicSubscribable) {
          if (!subscriptionContract.isActiveSubscription(msg.sender, address(this))) revert NotSubscribed();
        } else if (oracleType == OracleType.Private) {
            if (!whitelist[msg.sender]) revert NotWhitelisted();
        } else if (oracleType != OracleType.PublicFree) {
            revert InvalidOracleType();
        }
        return super.latestRoundData();
        //  (uint80(roundId), latestAnswer, latestTimestamp, block.timestamp, uint80(roundId));
    }
}
