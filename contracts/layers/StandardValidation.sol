// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {Counters} from "../libraries/Counters.sol";
import {Base64} from "../libraries/Base64.sol";
import {Models} from "../libraries/Models.sol";

import {StandardStorageLayer} from "./StandardStorage.sol";

interface StandardValidationLayer {
    function validateAndMintStandard(Models.BasicStandard memory standard) external returns (bytes32);
}

contract StandardValidation is StandardValidationLayer, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicStandard;

    // Contract owner
    address payable private _contractOwner;

    // Standard Storage Contract Address
    address private _standardStorageAddress;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Pending Standards map
    mapping(bytes32 => Models.BasicStandard) private _pendingStandards;

    // New pending data event
    event NewPendingStandard(Models.BasicStandard standard);

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

    function validateAndMintStandard(Models.BasicStandard memory standard) external returns (bytes32) {
        return _requestStandardValidation(standard);
    }

    // MARK: - Chainlink integration

    function _requestStandardValidation(Models.BasicStandard memory standard) private returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        request.add("get", "https://validate.rinkeby.openbasin.io/datastore/validate/standard");

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);

        _pendingStandards[requestId] = standard;

        return requestId;
    }

    function fulfill(bytes32 _requestId, bool _valid) public recordChainlinkFulfillment(_requestId) {
        require(_valid, 'Validator denied transaction');
        require(_pendingStandards[_requestId].exists, 'Request ID does not exist');

        StandardStorageLayer(_standardStorageAddress).mint(_pendingStandards[_requestId]);

        delete _pendingStandards[_requestId];

        return;
    }
}