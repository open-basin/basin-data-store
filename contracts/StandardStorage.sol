// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";

interface StandardStorageLayer {

}

contract StandardStorage is StandardStorageLayer {

    using Counters for Counters.Counter;

    // Contract owner
    address payable private _contractOwner;

    // Token Ids for data
    Counters.Counter private _tokenIds;

    // Pending Standards map
    mapping(bytes32 => BasicStandard) private _pendingStandards;

    // Standards map
    mapping(uint256 => Standard) private _standards;

    // New Standard event
    event NewStandard(Standard standard);

    // New pending data event
    event NewPendingStandard(BasicStandard standard);

    // Basic Standard structure
    struct BasicStandard {
        string name;
        string schema;
        bool exists;
    }

    // Standard structure
    struct Standard {
        uint256 token;
        string name;
        string schema;
        bool exists;
    }
}