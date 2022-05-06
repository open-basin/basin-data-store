// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";

contract DataStore {

    using Counters for Counters.Counter;

    // Contract owner
    address payable private _contractOwner;

    // Token Ids for data
    Counters.Counter private _tokenIds;

    // Token Ids for standards
    Counters.Counter private _standardIds;

    // Pending Data map
    mapping(bytes32 => BasicData) private _pendingData;

    // Pending Standards map
    mapping(bytes32 => BasicStandard) private _pendingStandards;

    // Data map
    mapping(uint256 => Data) private _data;

    // Standards map
    mapping(uint256 => Standard) private _standards;

    // Owners of data map
    mapping(uint256 => address) private _dataOwners;

    // Standards of data map
    mapping(uint256 => uint256) private _dataStandards;

    // Mapping owner address to token count
    mapping(address => uint256) private _ownerBalances;

    // Mapping standard address to token count
    mapping(uint256 => uint256) private _standardBalances;

    // Mapping owner address to standards to token count
    mapping(address => mapping(uint256 => uint256))
        private _ownerStandardBalances;

    // New data event
    event NewData(Data data);

    // New Standard event
    event NewStandard(Standard standard);

    // New data transfer event
    event NewTransfer(Data data);

    // New data burn event
    event NewBurn(uint256 token);

    // New pending data event
    event NewPendingStandard(BasicStandard standard);

    // New pending data event
    event NewPendingData(BasicData data);

    // Basic Standard structure
    struct BasicStandard {
        string name;
        string schema;
        bool exists;
    }

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

    // Standard structure
    struct Standard {
        uint256 token;
        string name;
        string schema;
        bool exists;
    }
}