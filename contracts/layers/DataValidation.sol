// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Base64} from "../libraries/Base64.sol";
import {Models} from "../libraries/Models.sol";

import {DataStorageLayer} from "./DataStorage.sol";

interface DataValidationLayer {
    function validateAndMintData(Models.BasicData memory data)
        external
        payable
        returns (uint256);
}

contract DataValidation is DataValidationLayer, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicData;
    using Models for Models.OracleConfiguration;

    // Contract owner
    address payable private _contractOwner;

    // Surface Contract Address
    address private _surfaceAddress;

    // Data Storage Contract Address
    address private _dataStorageAddress;

    // Chainlink configurations
    Models.OracleConfiguration private _configuration;

    // Constructor
    constructor(
        address surfaceAddress,
        address dataStorageAddress,
        address link,
        address oracle,
        bytes32 jobId,
        uint256 fee,
        string memory endpoint
    ) payable {
        console.log("Data Validation contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _dataStorageAddress = dataStorageAddress;

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
        console.log("Data Validation Transaction failed.");
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

    /// @dev Changes the data storage contract address
    function changeDataStorageAddress(address dataStorageAddress)
        external
        _onlyOwner
    {
        _dataStorageAddress = dataStorageAddress;
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

    /// @dev Interface method to validate and mint new data
    function validateAndMintData(Models.BasicData memory data)
        external
        payable
        override
        _onlySurface
        returns (uint256)
    {
        uint256 token = DataStorageLayer(_dataStorageAddress).mint(data);

        _requestDataValidation(data, token);

        return token;
    }

    // MARK: - Chainlink integration

    /// @dev Requests standard validation from Chainlink oracle
    function _requestDataValidation(Models.BasicData memory data, uint256 token)
        private
    {
        Chainlink.Request memory request = buildChainlinkRequest(
            _configuration.jobId,
            address(this),
            this.fulfill.selector
        );

        request.add(
            "get",
            validatorEndpoint(token, data.standard, data.payload)
        );
        request.add("path", "token");

        sendChainlinkRequestTo(
            _configuration.oracle,
            request,
            _configuration.fee
        );
    }

    /// @dev Fulfills validated data
    function fulfill(bytes32 _requestId, uint256 _token)
        external
        recordChainlinkFulfillment(_requestId)
    {
        require(responseIsValid(_token), "Data Validator denied transaction");

        DataStorageLayer(_dataStorageAddress).fulfill(_token);
    }

    // MARK: - Helpers

    function validatorEndpoint(
        uint256 dataToken,
        uint256 standardToken,
        string memory payload
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _configuration.endpoint,
                    "?data=",
                    Strings.toString(dataToken),
                    "&standard=",
                    Strings.toString(standardToken),
                    "&payload=",
                    payload
                )
            );
    }

    function responseIsValid(uint256 respone) private pure returns (bool) {
        return respone > 0;
    }
}
