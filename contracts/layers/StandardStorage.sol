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

    function fulfill(uint256 token) external payable;

    function standardForToken(uint256 token)
        external
        view
        returns (Models.Standard memory);

    function allStandards() external view returns (Models.Standard[] memory);

    function standardsForMinter(address minter)
        external
        view
        returns (Models.Standard[] memory);
}

interface StandardVisibility {
    function standardIsFulfilled(uint256 token) external view returns (bool);
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

    // Token Ids for standards
    Counters.Counter private _tokenIds;

    // Fulfilled Ids for fulfilled standard
    Counters.Counter private _fulfilledId;

    // Standards map
    mapping(uint256 => Models.Standard) private _standards;

    // // Mapping standard to token count
    mapping(uint256 => uint256) private _standardBalances;

    // Mapping minter address to token count
    mapping(address => uint256) private _minterBalances;

    // Fulfilled Standard map
    mapping(uint256 => uint256) private _fulfilledStandards;

    // Minters of standard map
    mapping(uint256 => address) private _standardMinters;

    // New Standard event
    event NewStandard(
        uint256 indexed token,
        address indexed minter
    );

    // Constructor
    constructor(
        address surfaceAddress,
        address standardValidationAddress,
        address standardVisibilityStorageAddress
    ) payable {
        console.log("Standard Storage contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _standardValidationAddress = standardValidationAddress;
        _standardVisibilityStorageAddress = standardVisibilityStorageAddress;

        _tokenIds.increment();
    }

    /// @dev Contract fallback method
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
            msg.sender == _standardVisibilityStorageAddress,
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

    // MARK: - External Write Methods

    /// @dev Interface method to mint new standard
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

    /// @dev Interface method to fulfill validated standard
    function fulfill(uint256 token) external payable override _onlyValidator {
        _fulfillStandard(token);

        emit NewStandard(
            _standards[token].token,
            _standards[token].minter
        );
    }

    // MARK: - Fetch Methods

    /// @dev Standard for specified token
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

    /// @dev All standards in storage
    function allStandards()
        external
        view
        override
        _onlySurface
        returns (Models.Standard[] memory)
    {
        uint256 length = _fulfilledId.current();
        Models.Standard[] memory result = new Models.Standard[](length);

        for (uint256 i = 0; i < length; i += 1) {
            uint256 token = _fulfilledStandards[i];
            result[i] = Models.rawStandard(_standards[token]);
        }

        return result;
    }

    /// @dev Standards for specified minter address
    function standardsForMinter(address minter)
        external
        view
        override
        _onlySurface
        returns (Models.Standard[] memory)
    {
        require(_validAddress(minter), "Minter is not valid.");

        uint256 balance = _minterBalances[minter];
        Models.Standard[] memory result = new Models.Standard[](balance);

        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < _tokenIds.current() && counter < balance;
            i += 1
        ) {
            if (minter == _standardMinters[i]) {
                result[counter] = Models.rawStandard(_standards[i]);
                counter++;
            }
        }

        return result;
    }

    // MARK: - Minter

    /// @dev Mints a standard to the contract
    function _mintStandard(Models.Standard memory standard) private {
        require(!_standardExists(standard.token), "Standard already exists.");
        require(bytes(standard.schema).length > 0, "Schema is empty.");
        require(bytes(standard.name).length > 0, "Name is empty.");
        require(_validAddress(tx.origin), "Minter is invalid.");

        _standards[standard.token] = standard;
        _standardMinters[standard.token] = standard.minter;
    }

    /// @dev Fulfills a standard to the contract
    function _fulfillStandard(uint256 token) private {
        require(_standardIsPending(token), "Standard is not pending.");

        _fulfilledStandards[_fulfilledId.current()] = token;
        _fulfilledId.increment();

        _standardBalances[token]++;
        _minterBalances[_standards[token].minter]++;
    }

    // MARK: - Helpers

    function _validAddress(address adr) private pure returns (bool) {
        return adr != address(0);
    }

    function _isMinter(address minter, uint256 token)
        private
        view
        returns (bool)
    {
        return minter == _standardMinters[token];
    }

    function _standardExists(uint256 token) private view returns (bool) {
        return
            _standardMinters[token] != address(0) ||
            _standardBalances[token] != 0;
    }

    function _standardIsPending(uint256 token) private view returns (bool) {
        return _standardBalances[token] == 0;
    }

    function _standardIsFufilled(uint256 token) private view returns (bool) {
        return _standardBalances[token] != 0;
    }

    function standardIsFulfilled(uint256 token)
        external
        view
        override
        _onlyVisibility
        returns (bool)
    {
        return _standardIsFufilled(token);
    }
}
