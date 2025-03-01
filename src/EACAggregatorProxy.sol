// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import {AggregatorProxy} from "./chainlink/EACAggregatorProxy.sol";

/// @notice Minimal interface for subscription management
interface ISubscriptionManagement {
    function isActiveSubscription(address subscriber, address oracle) external view returns (bool);
}

/**
 * @title External Access Controlled Aggregator Proxy
 * @notice A trusted proxy for updating where current answers are read from
 * @notice This contract provides a consistent address for the
 * Aggregator and AggregatorV3Interface but delegates where it reads from to the owner, who is
 * trusted to update it.
 * @notice Only access enabled addresses are allowed to access getters for
 * aggregated answers and round information.
 */
contract EACAggregatorProxy is AggregatorProxy {

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

  /**
   * @notice Reads the current answer from aggregator delegated to.
   * @dev overridden function to add the checkAccess() modifier
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer()
    public
    view
    override
    checkAccess()
    returns (int256)
  {
    return super.latestAnswer();
  }

  /**
   * @notice get the latest completed round where the answer was updated. This
   * ID includes the proxy's phase, to make sure round IDs increase even when
   * switching to a newly deployed aggregator.
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp()
    public
    view
    override
    checkAccess()
    returns (uint256)
  {
    return super.latestTimestamp();
  }

  /**
   * @notice get past rounds answers
   * @param _roundId the answer number to retrieve the answer for
   * @dev overridden function to add the checkAccess() modifier
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(uint256 _roundId)
    public
    view
    override
    checkAccess()
    returns (int256)
  {
    return super.getAnswer(_roundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param _roundId the answer number to retrieve the updated timestamp for
   * @dev overridden function to add the checkAccess() modifier
   *
   * @dev #[deprecated] Use getRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(uint256 _roundId)
    public
    view
    override
    checkAccess()
    returns (uint256)
  {
    return super.getTimestamp(_roundId);
  }

  /**
   * @notice get the latest completed round where the answer was updated
   * @dev overridden function to add the checkAccess() modifier
   *
   * @dev #[deprecated] Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound()
    public
    view
    override
    checkAccess()
    returns (uint256)
  {
    return super.latestRound();
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param _roundId the round ID to retrieve the round data for
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(uint80 _roundId)
    public
    view
    checkAccess()
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.getRoundData(_roundId);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData()
    public
    view
    checkAccess()
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.latestRoundData();
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param _roundId the round ID to retrieve the round data for
   * @return roundId is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedGetRoundData(uint80 _roundId)
    public
    view
    checkAccess()
    hasProposal()
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.proposedGetRoundData(_roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @return roundId is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
  */
  function proposedLatestRoundData()
    public
    view
    checkAccess()
    hasProposal()
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.proposedLatestRoundData();
  }

  /**
   * @dev reverts if the caller does not have access by the accessController
   * contract or is the contract itself.
   */
  modifier checkAccess() {
   if (oracleType == OracleType.PublicSubscribable) {
        if (!subscriptionContract.isActiveSubscription(msg.sender, address(this))) revert NotSubscribed();
    } else if (oracleType == OracleType.Private) {
        if (!whitelist[msg.sender]) revert NotWhitelisted();
    } else if (oracleType != OracleType.PublicFree) {
        revert InvalidOracleType();
    }
    _;
  }
}