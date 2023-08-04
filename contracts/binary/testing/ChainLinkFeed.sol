// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import "../../interfaces/binary/IOracle.sol";
import "../../interfaces/binary/AggregatorV3Interface.sol";

contract ChainLinkFeed is IOracle {
    /// @dev Pair name - BTCUSD
    string public pairName;
    AggregatorV3Interface public priceFeed;

    constructor(string memory _pairName, AggregatorV3Interface _priceFeed) {
        require(address(_priceFeed) != address(0), "ZERO_ADDRESS");
        pairName = _pairName;
        priceFeed = _priceFeed;
    }

    /**
     * @dev writable?
     */
    function isWritable() external pure override returns (bool) {
        return false;
    }

    /**
     * @dev Get latest round data
     */
    function getLatestRoundData()
        external
        view
        override
        returns (uint256 timestamp, uint256 price)
    {
        (, int256 _price, , uint256 _timestamp, ) = priceFeed.latestRoundData();
        timestamp = _timestamp;
        price = uint256(_price);
    }

    // solhint-disable-next-line
    function writePrice(uint256 timestamp, uint256 price) external override {}
}
