// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";

contract DataStorage {

    using Counters for Counters.Counter;

    // Contract owner
    address payable private _contractOwner;

    // Token Ids for data
    Counters.Counter private _tokenIds; 

    // Pending Data map
    mapping(bytes32 => BasicData) private _pendingData;

    // Data map
    mapping(uint256 => Data) private _data;

    // Owners of data map
    mapping(uint256 => address) private _dataOwners;

    // Standards of data map
    mapping(uint256 => uint256) private _dataStandards;

    // Mapping owner address to token count
    mapping(address => uint256) private _ownerBalances;

    // Mapping standard address to token count
    mapping(uint256 => uint256) private _standardBalances;

    // Mapping owner address to standards to token count
    mapping(address => mapping(uint256 => uint256)) private _ownerStandardBalances;

    // New data event
    event NewData(Data data);

    // New data transfer event
    event NewTransfer(Data data);

    // New data burn event
    event NewBurn(uint256 token);

    // New pending data event
    event NewPendingData(BasicData data);

    // Basin Data structure
    struct BasicData {
        address owner;
        uint256 standard;
        string payload;
        bool exists;
    }

    // Data structure
    struct Data {
        uint256 token;
        address owner;
        uint256 standard;
        uint256 timestamp;
        string payload;
    }
}