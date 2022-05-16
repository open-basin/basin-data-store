// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Base64} from "../libraries/Base64.sol";
import {Models} from "../libraries/Models.sol";

import {StandardStorageLayer} from "./StandardStorage.sol";

interface StandardValidationLayer {
    function validateAndMintStandard(Models.BasicStandard memory standard)
        external
        payable
        returns (bytes32);

    function pendingStandardForToken(uint256 token)
        external
        view
        returns (Models.BasicStandard memory);
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
        address link,
        address oracle,
        bytes32 jobId,
        uint256 fee,
        string memory endpoint
    ) payable {
        _tokenIds.increment();

        console.log(
            "StandardValidation contract constructed by %s",
            msg.sender
        );
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _standardStorageAddress = standardStorageAddress;

        setChainlinkToken(link);
        setChainlinkOracle(oracle);
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
        payable
        override
        _onlySurface
        returns (bytes32)
    {
        return _requestStandardValidation(standard);
    }

    function pendingStandardForToken(uint256 token)
        external
        view
        override
        returns (Models.BasicStandard memory)
    {
        require(tokenExists(token), "Pending Token does not exist");

        return _pendingStandards[token];
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

        request.add("get", validatorEndpoint(token, standard.schema));
        request.add("path", "token");

        return sendChainlinkRequest(request, _fee);
    }

    function fulfill(bytes32 _requestId, uint256 _token)
        public
        recordChainlinkFulfillment(_requestId)
    {
        require(
            responseIsValid(_token),
            "Standard Validator denied transaction"
        );
        require(tokenExists(_token), "Pending Token does not exist");

        StandardStorageLayer(_standardStorageAddress).mint(
            _pendingStandards[_token]
        );

        delete _pendingStandards[_token];

        return;
    }

    // MARK: - Helpers

    function validatorEndpoint(uint256 standardToken, string memory schema)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _endpoint,
                    "?token=",
                    Strings.toString(standardToken),
                    "&schema=",
                    schema
                )
            );
    }

    function tokenExists(uint256 token) private view returns (bool) {
        return _pendingStandards[token].exists;
    }

    function responseIsValid(uint256 respone) private pure returns (bool) {
        return respone > 0;
    }
}
