// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Models} from "../libraries/Models.sol";

interface StandardStorageLayer {
    function mint(Models.BasicStandard memory basicStandard)
        external
        payable
        returns (uint256);

    function fullfill(uint256 token) external payable;

    function standardForToken(uint256 token)
        external
        view
        returns (Models.Standard memory);

    function allStandards() external view returns (Models.Standard[] memory);
}

interface StandardVisibility {
    function standardIsFullfilled(uint256 token) external view returns (bool);
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

    // Token Ids for standards
    Counters.Counter private _tokenIds;

    // Fullfilled Ids for fullfilled standard
    Counters.Counter private _fullfilledId;

    // Standards map
    mapping(uint256 => Models.Standard) private _standards;

    // Standard Balance
    mapping(uint256 => uint256) private _standardBalance;

    // Fullfilled Standard map
    mapping(uint256 => uint256) private _fullfilledStandards;

    // Minters of standard map
    mapping(uint256 => address) private _standardMinters;

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

        _tokenIds.increment();
    }

    fallback() external {
        console.log("Standard Storage Transaction failed.");
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
        returns (uint256)
    {
        Models.Standard memory standard = Models.Standard(
            _tokenIds.current(),
            basicStandard.minter,
            basicStandard.name,
            basicStandard.schema
        );

        _mintStandard(standard);

        _tokenIds.increment();

        return standard.token;
    }

    function fullfill(uint256 token) external payable override _onlyValidator {
        _fullfillStandard(token);

        emit NewStandard(Models.rawStandard(_standards[token]));
    }

    function standardForToken(uint256 token)
        external
        view
        override
        _onlySurface
        returns (Models.Standard memory)
    {
        require(_standardIsFufilled(token), "Standard token in invalid");

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
        uint256 length = _fullfilledId.current();
        Models.Standard[] memory result = new Models.Standard[](length);

        for (uint256 i = 0; i < length; i += 1) {
            uint256 token = _fullfilledStandards[i];
            result[i] = Models.rawStandard(_standards[token]);
        }

        return result;
    }

    // MARK: - Minter

    /// @dev Mints a standard to the contract
    function _mintStandard(Models.Standard memory standard) private {
        require(!_standardExists(standard.token), "Standard already exists.");

        _standards[standard.token] = standard;
        _standardMinters[standard.token] = standard.minter;
    }

    /// @dev Fullfills a standard to the contract
    function _fullfillStandard(uint256 token) private {
        require(_standardIsPending(token), "Standard is not pending.");

        _fullfilledStandards[_fullfilledId.current()] = token;
        _fullfilledId.increment();

        _standardBalance[token]++;
    }

    // MARK: - Helpers

    function _standardExists(uint256 token) private view returns (bool) {
        return
            _standardMinters[token] != address(0) ||
            _standardBalance[token] != 0;
    }

    function _standardIsPending(uint256 token) private view returns (bool) {
        return _standardBalance[token] == 0;
    }

    function _standardIsFufilled(uint256 token) private view returns (bool) {
        return _standardBalance[token] != 0;
    }

    function standardIsFullfilled(uint256 token)
        external
        view
        override
        _onlyVisibility
        returns (bool)
    {
        return _standardIsFufilled(token);
    }
}
