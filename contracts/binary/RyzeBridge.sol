// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../lzApp/NonblockingLzApp.sol";
import "../interfaces/binary/IERC20Mintable.sol";

contract RyzeBridge is NonblockingLzApp {
    uint public counter;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    mapping(address => address) public assets; // src chain asset address => dst chain asset address

    uint256 public currentState;

    /// @dev Internal function to handle incoming Ping messages.
    /// @param _payload The payload of the incoming message.
    function _nonblockingLzReceive(
        uint16,
        bytes memory /*_srcAddress*/,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        (
            address receipent,
            address[] memory _assets,
            uint256[] memory _amounts,
            uint256 _stateForChanges
        ) = abi.decode(_payload, (address, address[], uint256[], uint256));

        require(_assets.length == _amounts.length, "Invalid array length");

        for (uint256 i; i < _assets.length; i++) {
            IERC20Mintable(_assets[i]).mint(receipent, _amounts[i]);
        }

        currentState = _stateForChanges;
    }

    function estimateFee(
        uint16 _dstChainId,
        address[] memory _assets,
        uint256[] memory _amounts,
        bool _useZro,
        bytes calldata _adapterParams,
        uint256 _stateForChanges
    ) public view returns (uint nativeFee, uint zroFee) {
        require(_assets.length == _amounts.length, "Invalid array length");
        // encode the payload with the token addresses and token amounts
        address[] memory dstAssets = new address[](_assets.length);
        for (uint i; i < _assets.length; i++) {
            dstAssets[i] = assets[_assets[i]];
        }

        bytes memory payload = _stateForChanges == 0
            ? abi.encode(msg.sender, dstAssets, _amounts)
            : abi.encode(msg.sender, dstAssets, _amounts, _stateForChanges);

        return
            lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function bridgeAssets(
        uint16 _dstChainId,
        address[] memory _assets,
        uint256[] memory _amounts,
        bytes calldata _adapterParams,
        uint256 _stateForChanges
    ) external payable {
        require(_assets.length == _amounts.length, "Invalid array length");
        // encode the payload with the token addresses and token amounts
        address[] memory dstAssets = new address[](_assets.length);
        for (uint i; i < _assets.length; i++) {
            dstAssets[i] = assets[_assets[i]];
        }

        bytes memory payload = _stateForChanges == 0
            ? abi.encode(msg.sender, dstAssets, _amounts)
            : abi.encode(msg.sender, dstAssets, _amounts, _stateForChanges);

        // Burn assets from msg.sender
        for (uint256 i; i < _assets.length; i = i + 1) {
            ERC20Burnable(_assets[i]).burnFrom(msg.sender, _amounts[i]);
        }

        _lzSend(
            _dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            _adapterParams,
            msg.value
        );
    }

    // allow this contract to receive ether
    receive() external payable {}

    function setDestAsset(
        address[] memory srcAssets,
        address[] memory dstAssets
    ) external onlyOwner {
        require(srcAssets.length == dstAssets.length, "Invalid array length");
        for (uint i; i < srcAssets.length; i++) {
            assets[srcAssets[i]] = dstAssets[i];
        }
    }
}
