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
        returns (uint256);
}

contract StandardValidation is StandardValidationLayer, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicStandard;
    using Models for Models.OracleConfiguration;

    // Contract owner
    address payable private _contractOwner;

    // Surface Contract Address
    address private _surfaceAddress;

    // Standard Storage Contract Address
    address private _standardStorageAddress;

    // Chainlink configurations
    Models.OracleConfiguration private _configuration;

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
        console.log(
            "Standard Validation contract constructed by %s",
            msg.sender
        );
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _standardStorageAddress = standardStorageAddress;

        setChainlinkToken(link);

        _configuration = Models.OracleConfiguration(
            oracle,
            jobId,
            fee,
            endpoint
        );
    }

    /// @dev Contract fallback method
    fallback() external {
        console.log("Standard Validation Transaction failed.");
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

    /// @dev Changes the chainlink confiugrations
    function changeChailinkConfiguration(
        address oracle,
        bytes32 jobId,
        uint256 fee,
        string memory endpoint
    ) external _onlyOwner {
        _configuration = Models.OracleConfiguration(
            oracle,
            jobId,
            fee,
            endpoint
        );
    }

    // MARK: - Public

    /// @dev Interface method to validate and mint a new standard
    function validateAndMintStandard(Models.BasicStandard memory standard)
        external
        payable
        override
        _onlySurface
        returns (uint256)
    {
        uint256 token = StandardStorageLayer(_standardStorageAddress).mint(
            standard
        );

        _requestStandardValidation(standard, token);

        return token;
    }

    // MARK: - Chainlink integration

    /// @dev Requests standard validation from Chainlink oracle
    function _requestStandardValidation(
        Models.BasicStandard memory standard,
        uint256 token
    ) private {
        Chainlink.Request memory request = buildChainlinkRequest(
            _configuration.jobId,
            address(this),
            this.fulfill.selector
        );

        request.add("get", validatorEndpoint(token, standard.schema));
        request.add("path", "token");

        sendChainlinkRequestTo(
            _configuration.oracle,
            request,
            _configuration.fee
        );
    }

    /// @dev Fulfills validated standard
    function fulfill(bytes32 _requestId, uint256 _token)
        external
        recordChainlinkFulfillment(_requestId)
    {
        require(
            responseIsValid(_token),
            "Standard Validator denied transaction"
        );

        StandardStorageLayer(_standardStorageAddress).fulfill(_token);
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
                    _configuration.endpoint,
                    "?token=",
                    Strings.toString(standardToken),
                    "&schema=",
                    schema
                )
            );
    }

    function responseIsValid(uint256 respone) private pure returns (bool) {
        return respone > 0;
    }
}
