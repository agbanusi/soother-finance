//////////////////////////////
// Minimal AggregatorProxy & MockAggregator for Proxy Testing
//////////////////////////////

// A minimal mock aggregator returning fixed values.
contract MockAggregator {
    int256 public fixedAnswer = 100;
    
    function latestAnswer() external view returns (int256) {
         return fixedAnswer;
    }
    function latestTimestamp() external view returns (uint256) {
         return block.timestamp;
    }
    function getAnswer(uint256) external view returns (int256) {
         return fixedAnswer;
    }
    function getTimestamp(uint256) external view returns (uint256) {
         return block.timestamp;
    }
    function latestRound() external view returns (uint256) {
         return 1;
    }
    function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80) {
         return (1, fixedAnswer, block.timestamp, block.timestamp, 1);
    }
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
         return (1, fixedAnswer, block.timestamp, block.timestamp, 1);
    }
    function proposedGetRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80) {
         return (1, fixedAnswer, block.timestamp, block.timestamp, 1);
    }
    function proposedLatestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
         return (1, fixedAnswer, block.timestamp, block.timestamp, 1);
    }
}

// // A simple AggregatorProxy that “delegates” calls to the mock aggregator.
// contract AggregatorProxy {
//     address public aggregator;

//     constructor(address _aggregator) {
//         aggregator = _aggregator;
//     }
//     function latestAnswer() public view virtual returns (int256) {
//         return MockAggregator(aggregator).latestAnswer();
//     }
//     function latestTimestamp() public view virtual returns (uint256) {
//         return MockAggregator(aggregator).latestTimestamp();
//     }
//     function getAnswer(uint256 _roundId) public view virtual returns (int256) {
//         return MockAggregator(aggregator).getAnswer(_roundId);
//     }
//     function getTimestamp(uint256 _roundId) public view virtual returns (uint256) {
//         return MockAggregator(aggregator).getTimestamp(_roundId);
//     }
//     function latestRound() public view virtual returns (uint256) {
//         return MockAggregator(aggregator).latestRound();
//     }
//     function getRoundData(uint80 _roundId) public view virtual returns (uint80, int256, uint256, uint256, uint80) {
//         return MockAggregator(aggregator).getRoundData(_roundId);
//     }
//     function latestRoundData() public view virtual returns (uint80, int256, uint256, uint256, uint80) {
//         return MockAggregator(aggregator).latestRoundData();
//     }
//     function proposedGetRoundData(uint80 _roundId) public view virtual returns (uint80, int256, uint256, uint256, uint80) {
//         return MockAggregator(aggregator).proposedGetRoundData(_roundId);
//     }
//     function proposedLatestRoundData() public view virtual returns (uint80, int256, uint256, uint256, uint80) {
//         return MockAggregator(aggregator).proposedLatestRoundData();
//     }
// }