// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Models} from "../libraries/Models.sol";

import {StandardVisibility} from "./StandardStorage.sol";

interface DataStorageLayer {
    function mint(Models.BasicData memory basicData)
        external
        payable
        returns (uint256);

    function fulfill(uint256 token) external payable;

    function burn(Models.Data memory data) external;

    function transfer(uint256 token, address to) external;

    function dataForToken(uint256 token)
        external
        view
        returns (Models.Data memory);

    function dataForOwner(address owner)
        external
        view
        returns (Models.Data[] memory);

    function dataForStandard(uint256 standard)
        external
        view
        returns (Models.Data[] memory);

    function dataForOwnerInStandard(address owner, uint256 standard)
        external
        view
        returns (Models.Data[] memory);

    function dataForProvider(address provider)
        external
        view
        returns (Models.Data[] memory);
}

contract DataStorage is DataStorageLayer {
    using Counters for Counters.Counter;
    using Models for Models.Data;
    using Models for Models.BasicData;

    // Surface Contract Address
    address private _surfaceAddress;

    // Data Validation Contract Address
    address private _dataValidationAddress;

    // Standard Visibiliy Contract Address
    address private _standardVisibilityAddress;

    // Contract owner
    address payable private _contractOwner;

    // Token Ids for data
    Counters.Counter private _tokenIds;

    // Fulfilled Ids for fulfilled data
    Counters.Counter private _fulfilledId;

    // Data map
    mapping(uint256 => Models.Data) private _data;

    // Data Balance
    mapping(uint256 => uint256) private _dataBalance;

    // Fulfilled Data map
    mapping(uint256 => uint256) private _fulfilledData;

    // Owners of data map
    mapping(uint256 => address) private _dataOwners;

    // Standards of data map
    mapping(uint256 => uint256) private _dataStandards;

    // Mapping owner address to token count
    mapping(address => uint256) private _ownerBalances;

    // Mapping provider address to token count
    mapping(address => uint256) private _providerBalances;

    // Mapping standard address to token count
    mapping(uint256 => uint256) private _standardBalances;

    // Mapping owner address to standards to token count
    mapping(address => mapping(uint256 => uint256))
        private _ownerStandardBalances;

    // New data event
    event NewData(Models.Data data);

    // New data transfer event
    event NewTransfer(Models.Data data);

    // New data burn event
    event NewBurn(uint256 token);

    // Constructor
    constructor(
        address surfaceAddress,
        address dataValidationAddress,
        address standardVisibilityAddress
    ) payable {
        console.log("Data Storage contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _dataValidationAddress = dataValidationAddress;
        _standardVisibilityAddress = standardVisibilityAddress;

        _tokenIds.increment();
    }

    /// @dev Contract fallback method
    fallback() external {
        console.log("Data Storage Transaction failed.");
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

    /// @dev Checks if the signer is the contract's data validator
    modifier _onlyValidator() {
        require(
            msg.sender == _dataValidationAddress,
            "Must be contract data validator"
        );
        _;
    }

    /// @dev Changes the surface contract address
    function changeSurfaceAddress(address surfaceAddress) external _onlyOwner {
        _surfaceAddress = surfaceAddress;
    }

    /// @dev Changes the data validation contract address
    function changeDataValidationAddress(address dataValidationAddress)
        external
        _onlyOwner
    {
        _dataValidationAddress = dataValidationAddress;
    }

    /// @dev Changes the standard visibility contract address
    function changeStandardVisibilityAddress(address standardVisibilityAddress)
        external
        _onlyOwner
    {
        _standardVisibilityAddress = standardVisibilityAddress;
    }

    // MARK: - External Write Methods

    /// @dev Interface method to mint new data
    function mint(Models.BasicData memory basicData)
        external
        payable
        override
        _onlyValidator
        returns (uint256)
    {
        Models.Data memory data = Models.Data(
            _tokenIds.current(),
            basicData.owner,
            basicData.provider,
            basicData.standard,
            block.timestamp,
            basicData.payload
        );

        _mintData(data);

        _tokenIds.increment();

        return data.token;
    }

    /// @dev Interface method to fulfill validated data
    function fulfill(uint256 token) external payable override _onlyValidator {
        _fulfillData(token);

        emit NewData(_data[token]);
    }

    /// @dev Interface method to burn data
    function burn(Models.Data memory data) external override _onlySurface {
        _burnData(data);

        emit NewBurn(data.token);

        return;
    }

    /// @dev Interface method to transfer data
    function transfer(uint256 token, address to)
        external
        override
        _onlySurface
    {
        _transferData(token, to);

        emit NewTransfer(_data[token]);

        return;
    }

    // MARK: - Fetch methods

    /// @dev Data for a specified token
    function dataForToken(uint256 token)
        external
        view
        override
        _onlySurface
        returns (Models.Data memory)
    {
        require(_tokenExists(token), "Data token in invalid");

        Models.Data memory result = _data[token];

        return Models.rawData(result);
    }

    /// @dev Data for a specified owner address
    function dataForOwner(address owner)
        external
        view
        override
        _onlySurface
        returns (Models.Data[] memory)
    {
        require(_validAddress(owner), "Owner is not valid.");

        uint256 balance = _ownerBalances[owner];
        Models.Data[] memory result = new Models.Data[](balance);

        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < _tokenIds.current() && counter < balance;
            i += 1
        ) {
            if (owner == _dataOwners[i]) {
                result[counter] = Models.rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    /// @dev Data for a specified standard
    function dataForStandard(uint256 standard)
        external
        view
        override
        _onlySurface
        returns (Models.Data[] memory)
    {
        require(_standardExists(standard), "Standard does not exist.");

        uint256 balance = _standardBalances[standard];
        Models.Data[] memory result = new Models.Data[](balance);

        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < _tokenIds.current() && counter < balance;
            i += 1
        ) {
            if (standard == _dataStandards[i]) {
                result[counter] = Models.rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    /// @dev Data for a specified owner and standard
    function dataForOwnerInStandard(address owner, uint256 standard)
        external
        view
        override
        _onlySurface
        returns (Models.Data[] memory)
    {
        require(_validAddress(owner), "Owner is not valid.");
        require(_standardExists(standard), "Standard does not exist.");

        uint256 balance = _ownerStandardBalances[owner][standard];
        Models.Data[] memory result = new Models.Data[](balance);

        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < _tokenIds.current() && counter < balance;
            i += 1
        ) {
            if (owner == _dataOwners[i] && standard == _dataStandards[i]) {
                result[counter] = Models.rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    /// @dev Data for a specified provider
    function dataForProvider(address provider)
        external
        view
        override
        _onlySurface
        returns (Models.Data[] memory)
    {
        require(_validAddress(provider), "Provider is not valid.");

        uint256 balance = _providerBalances[provider];
        Models.Data[] memory result = new Models.Data[](balance);

        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < _tokenIds.current() && counter < balance;
            i += 1
        ) {
            if (provider == _data[i].provider) {
                result[counter] = Models.rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    // MARK: - Minters

    /// @dev Mints data to the contract
    function _mintData(Models.Data memory data) private {
        require(_isValidData(data), "Data is invalid.");

        // Writes data to contract
        _data[data.token] = data;
    }

    /// @dev Fulfills Data to the contract
    function _fulfillData(uint256 token) private {
        require(_dataIsPending(token), "Standard is not pending.");

        Models.Data memory data = _data[token];

        _fulfilledData[_fulfilledId.current()] = token;
        _fulfilledId.increment();

        _dataOwners[data.token] = data.owner;
        _dataStandards[data.token] = data.standard;

        // Increments balances
        _ownerBalances[data.owner]++;
        _providerBalances[data.provider]++;
        _standardBalances[data.standard]++;
        _ownerStandardBalances[data.owner][data.standard]++;

        _dataBalance[token]++;
    }

    /// @dev Burns data from contract
    function _burnData(Models.Data memory data) private {
        require(_tokenExists(data.token), "Data is invalid.");
        require(_validAddress(tx.origin), "Owner address is invalid.");
        require(_isOwner(tx.origin, data.token), "Owner is invalid.");

        // Increments balances
        _ownerBalances[data.owner]--;
        _standardBalances[data.standard]--;
        _ownerStandardBalances[data.owner][data.standard]--;

        // Removes owners from data
        delete _dataOwners[data.token];
        delete _dataStandards[data.token];
        delete _dataBalance[data.token];
    }

    // MARK: - Transfer methods

    /// @dev Transfers data from owner to address
    function _transferData(uint256 token, address to) private {
        require(_tokenExists(token), "Data does not exists.");
        require(_validAddress(tx.origin), "Owner address is invalid.");
        require(_isOwner(tx.origin, token), "Owner is invalid.");
        require(_validAddress(to), "Destination address is invalid.");

        _data[token].owner = to;
        _dataOwners[token] = to;

        _ownerBalances[to]++;
        _ownerBalances[tx.origin]--;
    }

    // MARK: - Helpers

    function _isValidData(Models.Data memory data) private view returns (bool) {
        return
            _validAddress(data.owner) &&
            bytes(data.payload).length > 0 &&
            _validProvider(data.provider) &&
            !_dataExists(data.token) &&
            _standardExists(data.standard);
    }

    function _validAddress(address adr) private pure returns (bool) {
        return adr != address(0);
    }

    function _validProvider(address provider) private pure returns (bool) {
        return provider != address(0);
    }

    function _tokenExists(uint256 token) private view returns (bool) {
        return _dataOwners[token] != address(0);
    }

    function _isOwner(address owner, uint256 token)
        private
        view
        returns (bool)
    {
        return owner == _dataOwners[token];
    }

    function _dataExists(uint256 token) private view returns (bool) {
        return _dataOwners[token] != address(0) || _dataBalance[token] > 0;
    }

    function _dataIsPending(uint256 token) private view returns (bool) {
        return _dataBalance[token] == 0;
    }

    function _dataIsFufilled(uint256 token) private view returns (bool) {
        return _dataBalance[token] != 0;
    }

    function _standardExists(uint256 token) private view returns (bool) {
        return
            StandardVisibility(_standardVisibilityAddress).standardIsFulfilled(
                token
            );
    }
}
