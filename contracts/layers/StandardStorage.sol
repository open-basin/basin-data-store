// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "../libraries/Counters.sol";
import {Models} from "../libraries/Models.sol";

interface StandardStorageLayer {
    function mint(Models.BasicStandard memory basicStandard) external;

    function standardForToken(uint256 token)
        external
        view
        returns (Models.Standard memory);

    function allStandards() external view returns (Models.Standard[] memory);
}

interface StandardVisibility {
    function standardExists(uint256 standardId) external view returns (bool);
}

contract StandardStorage is StandardStorageLayer, StandardVisibility {
    using Counters for Counters.Counter;
    using Models for Models.Standard;
    using Models for Models.BasicStandard;

    // Contract owner
    address payable private _contractOwner;

    // Token Ids for data
    Counters.Counter private _tokenIds;

    // Standards map
    mapping(uint256 => Models.Standard) private _standards;

    // New Standard event
    event NewStandard(Models.Standard standard);

    // Constrcutor
    constructor() payable {
        console.log("StandardStorage contract constructed by %s", msg.sender);
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
    function changeOwner(address payable newOwner) external _onlyOwner {
        _contractOwner = newOwner;
    }

    // MARK: - External

    function mint(Models.BasicStandard memory basicStandard) external {
        Models.Standard memory standard = Models.Standard(
            _tokenIds.current(),
            basicStandard.name,
            basicStandard.schema,
            true
        );

        _mintStandard(standard);

        _tokenIds.increment();

        emit NewStandard(Models.rawStandard(standard));

        return;
    }

    function standardForToken(uint256 token)
        external
        view
        returns (Models.Standard memory)
    {
        require(_standardExists(token), "Standard token in invalid");

        Models.Standard memory result = _standards[token];

        return Models.rawStandard(result);
    }

    function allStandards() external view returns (Models.Standard[] memory) {
        uint256 length = _tokenIds.current();
        Models.Standard[] memory result = new Models.Standard[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = Models.rawStandard(_standards[i]);
        }

        return result;
    }

    // MARK: - Minter

    /// @dev Mints a standard to the contract
    function _mintStandard(Models.Standard memory standard) private {
        require(!_standardExists(standard.token), "Standard already exists.");

        _standards[standard.token] = standard;
    }

    // MARK: - Helpers

    function _standardExists(uint256 standardId) private view returns (bool) {
        return standardId < _tokenIds.current();
    }

    function standardExists(uint256 standardId) external view returns (bool) {
        return standardId < _tokenIds.current();
    }
}
