// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {Counters} from "../libraries/Counters.sol";
import {Base64} from "../libraries/Base64.sol";
import {Models} from "../libraries/Models.sol";

import {StandardStorageLayer} from "./StandardStorage.sol";

interface StandardValidationLayer {
    function validateAndMintStandard(Models.BasicStandard memory standard)
        external
        returns (bytes32);
}

contract StandardValidation is StandardValidationLayer, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicStandard;

    // Contract owner
    address payable private _contractOwner;

    // Surface Contract Address
    address private _surfaceAddress;

    // Standard Storage Contract Address
    address private _standardStorageAddress;

    // Chainlink configurations
    address private _oracle;
    bytes32 private _jobId;
    uint256 private _fee;
    string private _endpoint;

    // Token Ids for pending standards
    Counters.Counter private _tokenIds;

    // Pending Standards map
    mapping(uint256 => Models.BasicStandard) private _pendingStandards;

    // New pending data event
    event NewPendingStandard(Models.BasicStandard standard);

    // Constructor
    constructor(
        address surfaceAddress,
        address standardStorageAddress,
        address oracle,
        bytes32 jobId,
        uint256 fee,
        string memory endpoint
    ) payable {
        console.log("DataValidation contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _standardStorageAddress = standardStorageAddress;

        _oracle = oracle;
        _jobId = jobId;
        _fee = fee;
        _endpoint = endpoint;
    }

    fallback() external {
        console.log("Transaction failed.");
    }

    /// @dev Checks if the signer is the contract owner
    modifier _onlyOwner() {
        require(msg.sender == _contractOwner, "Must be contract owner.");
        _;
    }

    /// @dev Changes contract owner
    function changeOwner(address payable newOwner) public _onlyOwner {
        _contractOwner = newOwner;
    }

    /// @dev Checks if the signer is the contract's surface
    modifier _onlySurface() {
        require(msg.sender == _surfaceAddress, "Must be contract's surface");
        _;
    }

    /// @dev Changes the surface contract address
    function changeSurfaceAddress(address surfaceAddress) external _onlyOwner {
        _surfaceAddress = surfaceAddress;
    }

    /// @dev Changes the standard storage contract address
    function changeStandardStorageAddress(address standardStorageAddress)
        external
        _onlyOwner
    {
        _standardStorageAddress = standardStorageAddress;
    }

    // MARK: - Public

    function validateAndMintStandard(Models.BasicStandard memory standard)
        external
        _onlySurface
        returns (bytes32)
    {
        return _requestStandardValidation(standard);
    }

    // MARK: - Chainlink integration

    function _requestStandardValidation(Models.BasicStandard memory standard)
        private
        returns (bytes32)
    {
        Chainlink.Request memory request = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfill.selector
        );

        uint256 token = _tokenIds.current();
        _tokenIds.increment();

        _pendingStandards[token] = standard;

        request.add("get", validatorEndpoint(token));

        return sendChainlinkRequestTo(_oracle, request, _fee);
    }

    function fulfill(
        bytes32 _requestId,
        bool _valid,
        uint256 _token
    ) external recordChainlinkFulfillment(_requestId) {
        require(_valid, "Validator denied transaction");
        require(_pendingStandards[_token].exists, "Request ID does not exist");

        StandardStorageLayer(_standardStorageAddress).mint(
            _pendingStandards[_token]
        );

        delete _pendingStandards[_token];

        return;
    }

    // MARK: - Helpers

    function validatorEndpoint(uint256 standardToken)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_endpoint, Strings.toString(standardToken))
            );
    }
}
