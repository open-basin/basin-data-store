// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Models} from "../libraries/Models.sol";

import {StandardVisibility} from "./StandardStorage.sol";

interface DataStorageLayer {
    function mint(Models.BasicData memory basicData) external payable;

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

    // Data map
    mapping(uint256 => Models.Data) private _data;

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
        console.log("DataStorage contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _surfaceAddress = surfaceAddress;
        _dataValidationAddress = dataValidationAddress;
        _standardVisibilityAddress = standardVisibilityAddress;
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

    // MARK: - External

    function mint(Models.BasicData memory basicData) external payable override _onlyValidator {
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

        emit NewData(data);

        return;
    }

    function burn(Models.Data memory data) external override _onlySurface {
        _burnData(data);

        emit NewBurn(data.token);

        return;
    }

    function transfer(uint256 token, address to) external override _onlySurface {
        _transferData(token, to);

        emit NewTransfer(_data[token]);

        return;
    }

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

    function dataForOwner(address owner)
        external
        view
        override
        _onlySurface
        returns (Models.Data[] memory)
    {
        require(_validOwner(owner), "Owner is not valid.");

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

    function dataForOwnerInStandard(address owner, uint256 standard)
        external
        view
        override
        _onlySurface
        returns (Models.Data[] memory)
    {
        require(_validOwner(owner), "Owner is not valid.");
        require(_standardExists(standard), "Standard does not exist.");

        uint256 balance = _ownerStandardBalances[owner][standard];
        Models.Data[] memory result = new Models.Data[](balance);

        uint256 counter = 0;
        for (uint256 i = 0; i < balance; i += 1) {
            if (owner == _dataOwners[i] && standard == _dataStandards[i]) {
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
        _dataOwners[data.token] = data.owner;
        _dataStandards[data.token] = data.standard;

        // Increments balances
        _ownerBalances[data.owner]++;
        _standardBalances[data.standard]++;
        _ownerStandardBalances[data.owner][data.standard]++;

        // Pay bank and provider
    }

    /// @dev Burns data from contract
    function _burnData(Models.Data memory data) private {
        require(_tokenExists(data.token), "Data is invalid.");
        require(_validOwner(msg.sender), "Owner address is invalid.");
        require(_isOwner(msg.sender, data.token), "Owner is invalid.");

        // Increments balances
        _ownerBalances[data.owner]--;
        _standardBalances[data.standard]--;
        _ownerStandardBalances[data.owner][data.standard]--;

        // Removes owners from data
        delete _dataOwners[data.token];
        delete _dataStandards[data.token];
    }

    // MARK: - Transfer methods

    function _transferData(uint256 token, address to) private {
        require(_tokenExists(token), "Data does not exists.");
        require(_validOwner(msg.sender), "Owner address is invalid.");
        require(_isOwner(msg.sender, token), "Owner is invalid.");
        require(_validOwner(to), "Destination address is invalid.");

        _data[token].owner = to;
        _dataOwners[token] = to;

        _ownerBalances[to]++;
        _ownerBalances[msg.sender]--;
    }

    // MARK: - Helpers

    function _isValidData(Models.Data memory data) private view returns (bool) {
        return
            _validOwner(data.owner) &&
            _validProvider(data.provider) &&
            !_tokenExists(data.token) &&
            _standardExists(data.standard);
    }

    function _validOwner(address owner) private pure returns (bool) {
        return owner != address(0);
    }

    function _validProvider(address provider) private pure returns (bool) {
        return provider != address(0);
    }

    function _tokenExists(uint256 tokenId) private view returns (bool) {
        return _dataOwners[tokenId] != address(0);
    }

    function _isOwner(address owner, uint256 token)
        private
        view
        returns (bool)
    {
        return owner == _dataOwners[token];
    }

    function _standardExists(uint256 standardId) private view returns (bool) {
        return
            StandardVisibility(_standardVisibilityAddress).standardExists(
                standardId
            );
    }
}
