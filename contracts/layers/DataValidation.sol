// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {Counters} from "../libraries/Counters.sol";
import {Base64} from "../libraries/Base64.sol";
import {Models} from "../libraries/Models.sol";

import {DataStorageLayer} from "./DataStorage.sol";

interface DataValidationLayer {
    function validateAndMintData(Models.BasicData memory data)
        external
        returns (bytes32);
}

contract DataValidation is DataValidationLayer, ChainlinkClient {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;
    using Models for Models.BasicData;

    // Contract owner
    address payable private _contractOwner;

    // Data Storage Contract Address
    address private _dataStorageAddress;

    address private _oracle;
    bytes32 private _jobId;
    uint256 private _fee;

    // Token Ids for pending data
    Counters.Counter private _tokenIds;

    // Pending Data map
    mapping(uint256 => Models.BasicData) private _pendingData;

    // New pending data event
    event NewPendingData(Models.BasicData data);

    // Constrcutor
    constructor() payable {
        console.log("DataValidation contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        // _dataStorageAddress = ; // TODO - Update to deployed address

        // _oracle = ; // TODO - Update
        // _jobId = ""; // TODO - Update
        // _fee = 0.1 * 10 ** 18; // TODO - Updatepdate
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

    function validateAndMintData(Models.BasicData memory data)
        external
        returns (bytes32)
    {
        return _requestDataValidation(data);
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
            string(
                abi.encodePacked(
                    "https://validate.rinkeby.openbasin.io/datastore/validate/data?data=",
                    Strings.toString(token),
                    "&standard=",
                    Strings.toString(data.standard)
                )
            )
        );
        request.add(
            "get",
            "https://validate.rinkeby.openbasin.io/datastore/validate/data"
        );

        return sendChainlinkRequestTo(_oracle, request, _fee);
    }

    function fulfill(
        bytes32 _requestId,
        bool _valid,
        uint256 _token
    ) public recordChainlinkFulfillment(_requestId) {
        require(_valid, "Validator denied transaction");
        require(_pendingData[_token].exists, "Request ID does not exist");

        DataStorageLayer(_dataStorageAddress).mint(_pendingData[_token]);

        delete _pendingData[_token];

        return;
    }
}
