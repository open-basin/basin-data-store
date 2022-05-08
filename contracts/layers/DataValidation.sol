// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {Counters} from "../libraries/Counters.sol";
import {Base64} from "../libraries/Base64.sol";
import {Models} from "../libraries/Models.sol";

import {DataStorageLayer} from "./DataStorage.sol";

interface DataValidationLayer {
    function validateAndMintData(Models.BasicData memory data) external returns (bytes32);
}

contract DataValidation is DataValidationLayer, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicData;

    // Contract owner
    address payable private _contractOwner;

    // Data Storage Contract Address
    address private _dataStorageAddress;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Pending Data map
    mapping(bytes32 => Models.BasicData) private _pendingData;

    // New pending data event
    event NewPendingData(Models.BasicData data);

    // Constrcutor
    constructor() payable {
        console.log("DataValidation contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);
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

    // MARK: - Public

    function validateAndMintData(Models.BasicData memory data) external returns (bytes32) {
        return _requestDataValidation(data);
    }

    // MARK: - Chainlink integration

    function _requestDataValidation(Models.BasicData memory data) private returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        request.add("get", "https://validate.rinkeby.openbasin.io/datastore/validate/data");

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);

        _pendingData[requestId] = data;

        return requestId;
    }

    function fulfill(bytes32 _requestId, bool _valid) public recordChainlinkFulfillment(_requestId) {
        require(_valid, 'Validator denied transaction');
        require(_pendingData[_requestId].exists, 'Request ID does not exist');

        DataStorageLayer(_dataStorageAddress).mint(_pendingData[_requestId]);

        delete _pendingData[_requestId];

        return;
    }
}