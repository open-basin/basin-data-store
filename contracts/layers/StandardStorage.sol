// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Models} from "../libraries/Models.sol";

interface StandardStorageLayer {
    function mint(Models.BasicStandard memory basicStandard) external payable;

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

    // Surface Contract Address
    address private _surfaceAddress;

    // Standard Validation Contract Address
    address private _standardValidationAddress;

    // Standard Visibility Storage Contract Address
    address private _standardVisibilityStorageAddress;

    // Standard Visibility Validation Contract Address
    address private _standardVisibilityValidationAddress;

    // Token Ids for data
    Counters.Counter private _tokenIds;

    // Standards map
    mapping(uint256 => Models.Standard) private _standards;

    // New Standard event
    event NewStandard(Models.Standard standard);

    // Constructor
    constructor(
        address surfaceAddress,
        address standardValidationAddress,
        address standardVisibilityStorageAddress,
        address standardVisibilityValidationAddress
    ) payable {
        console.log("StandardStorage contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _standardValidationAddress = standardValidationAddress;
        _standardVisibilityStorageAddress = standardVisibilityStorageAddress;
        _standardVisibilityValidationAddress = standardVisibilityValidationAddress;
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

    /// @dev Checks if the signer is the contract's surface
    modifier _onlySurface() {
        require(msg.sender == _surfaceAddress, "Must be contract's surface");
        _;
    }

    /// @dev Checks if the signer is the contract's standard validator
    modifier _onlyValidator() {
        require(
            msg.sender == _standardValidationAddress,
            "Must be contract's validator"
        );
        _;
    }

    /// @dev Checks if the signer is the contract's standard visibility address
    modifier _onlyVisibility() {
        require(
            msg.sender == _standardVisibilityStorageAddress ||
                msg.sender == _standardVisibilityValidationAddress,
            "Must be contract's visibility address"
        );
        _;
    }

    /// @dev Changes the surface contract address
    function changeSurfaceAddress(address surfaceAddress) external _onlyOwner {
        _surfaceAddress = surfaceAddress;
    }

    /// @dev Changes the standard validation contract address
    function changeStandardValidationAddress(address standardValidationAddress)
        external
        _onlyOwner
    {
        _standardValidationAddress = standardValidationAddress;
    }

    /// @dev Changes the standard visibility storage contract address
    function changeStandardVisibilityStorageAddress(
        address standardVisibilityStorageAddress
    ) external _onlyOwner {
        _standardVisibilityStorageAddress = standardVisibilityStorageAddress;
    }

    /// @dev Changes the standard visibility validation contract address
    function changeStandardVisibilityValidationAddress(
        address standardVisibilityValidationAddress
    ) external _onlyOwner {
        _standardVisibilityValidationAddress = standardVisibilityValidationAddress;
    }

    // MARK: - External

    function mint(Models.BasicStandard memory basicStandard)
        external
        payable
        override
        _onlyValidator
    {
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
        override
        _onlySurface
        returns (Models.Standard memory)
    {
        require(_standardExists(token), "Standard token in invalid");

        Models.Standard memory result = _standards[token];

        return Models.rawStandard(result);
    }

    function allStandards()
        external
        view
        override
        _onlySurface
        returns (Models.Standard[] memory)
    {
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

    function standardExists(uint256 standardId)
        external
        view
        override
        _onlyVisibility
        returns (bool)
    {
        return standardId < _tokenIds.current();
    }
}
