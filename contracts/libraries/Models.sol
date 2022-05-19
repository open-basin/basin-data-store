// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import {Base64} from "./Base64.sol";

library Models {
    // Basin Data structure
    struct BasicData {
        address owner;
        address provider;
        uint256 standard;
        string payload;
    }

    // Data structure
    struct Data {
        uint256 token;
        address owner;
        address provider;
        uint256 standard;
        uint256 timestamp;
        string payload;
    }

    // Basic Standard structure
    struct BasicStandard {
        address minter;
        string name;
        string schema;
    }

    // Standard structure
    struct Standard {
        uint256 token;
        address minter;
        string name;
        string schema;
    }

    // Oracle Configuration structure
    struct OracleConfiguration {
        address oracle;
        bytes32 jobId;
        uint256 fee;
        string endpoint;
    }

    /// @dev Gets the raw standard
    function rawStandard(Standard memory standard)
        internal
        pure
        returns (Standard memory)
    {
        Standard memory newStandard = Standard(
            standard.token,
            standard.minter,
            decoded(standard.name),
            decoded(standard.schema)
        );

        return newStandard;
    }

    /// @dev Gets the raw value
    function rawData(Data memory data) internal pure returns (Data memory) {
        Data memory newData = Data(
            data.token,
            data.owner,
            data.provider,
            data.standard,
            data.timestamp,
            decoded(data.payload)
        );

        return newData;
    }

    /// @dev Gets the raw standard
    function rawBasicStandard(BasicStandard memory standard)
        internal
        pure
        returns (BasicStandard memory)
    {
        BasicStandard memory newStandard = BasicStandard(
            standard.minter,
            decoded(standard.name),
            decoded(standard.schema)
        );

        return newStandard;
    }

    /// @dev Gets the raw value
    function rawBasicData(BasicData memory data)
        internal
        pure
        returns (BasicData memory)
    {
        BasicData memory newData = BasicData(
            data.owner,
            data.provider,
            data.standard,
            decoded(data.payload)
        );

        return newData;
    }

    /// @dev Encodes
    function encoded(string memory _payload)
        internal
        pure
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked(_payload)))
        );

        return json;
    }

    /// @dev Decodes
    function decoded(string memory _payload)
        internal
        pure
        returns (string memory)
    {
        bytes memory rawPayload = Base64.decode(_payload);

        return string(rawPayload);
    }
}
