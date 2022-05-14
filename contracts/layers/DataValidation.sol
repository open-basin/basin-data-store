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
        returns (bytes32);

    function pendingDataForToken(uint256 token)
        external
        view
        returns (Models.BasicData memory);
}

contract DataValidation is DataValidationLayer, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicData;

    // Contract owner
    address payable private _contractOwner;

    // Surface Contract Address
    address private _surfaceAddress;

    // Data Storage Contract Address
    address private _dataStorageAddress;

    // Chainlink configurations
    bytes32 private _jobId;
    uint256 private _fee;
    string private _endpoint;

    // Token Ids for pending data
    Counters.Counter private _tokenIds;

    // Pending Data map
    mapping(uint256 => Models.BasicData) private _pendingData;

    // New pending data event
    event NewPendingData(Models.BasicData data);

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
        _tokenIds.increment();

        console.log("DataValidation contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _dataStorageAddress = dataStorageAddress;

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

    /// @dev Changes the data storage contract address
    function changeDataStorageAddress(address dataStorageAddress)
        external
        _onlyOwner
    {
        _dataStorageAddress = dataStorageAddress;
    }

    // MARK: - Public

    function validateAndMintData(Models.BasicData memory data)
        external
        payable
        override
        _onlySurface
        returns (bytes32)
    {
        return _requestDataValidation(data);
    }

    function pendingDataForToken(uint256 token)
        external
        view
        override
        returns (Models.BasicData memory)
    {
        require(tokenExists(token), "Pending Token does not exist");

        return _pendingData[token];
    }

    // MARK: - Chainlink integration

    function _requestDataValidation(Models.BasicData memory data)
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

        _pendingData[token] = data;

        request.add(
            "get",
            validatorEndpoint(token, data.standard, data.payload)
        );
        request.add("path", "token");

        return sendChainlinkRequest(request, _fee);
    }

    function fulfill(bytes32 _requestId, uint256 _token)
        external
        recordChainlinkFulfillment(_requestId)
    {
        require(responseIsValid(_token), "Data Validator denied transaction");
        require(tokenExists(_token), "Pending Data ID does not exist");

        DataStorageLayer(_dataStorageAddress).mint(_pendingData[_token]);

        delete _pendingData[_token];

        return;
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
                    _endpoint,
                    "?data=",
                    Strings.toString(dataToken),
                    "&standard=",
                    Strings.toString(standardToken),
                    "&payload=",
                    payload
                )
            );
    }

    function tokenExists(uint256 token) private view returns (bool) {
        return _pendingData[token].exists;
    }

    function responseIsValid(uint256 respone) private pure returns (bool) {
        return respone > 0;
    }
}
