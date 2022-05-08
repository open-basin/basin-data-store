// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";
import {Models} from "./libraries/Models.sol";

import {DataStorageLayer} from "./layers/DataStorage.sol";
import {StandardStorageLayer} from "./layers/StandardStorage.sol";
import {DataValidationLayer} from "./layers/DataValidation.sol";
import {StandardValidationLayer} from "./layers/StandardValidation.sol";

contract DataStore {
    using Counters for Counters.Counter;
    using Models for *;

    // Contract owner
    address payable private _contractOwner;

    // Data Storage Contract Address
    address private _dataStorageAddress;

    // Standard Storage Contract Address
    address private _standardStorageAddress;

    // Data Validation Contract Address
    address private _dataValidationAddress;

    // Standard Validation Contract Address
    address private _standardValidationAddress;

    // MARK: - Contract Constructor

    // Constructor
    constructor(
        address dataStorageAddress,
        address standardStorageAddress,
        address dataValidationAddress,
        address standardValidationAddress
    ) payable {
        console.log("DataStore contract constructed by %s", msg.sender);
        _contractOwner = payable(msg.sender);

        _dataStorageAddress = dataStorageAddress;
        _standardStorageAddress = standardStorageAddress;
        _dataValidationAddress = dataValidationAddress;
        _standardValidationAddress = standardValidationAddress;
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

    /// @dev Changes the data storage contract address
    function changeDataStorageAddress(address dataStorageAddress)
        external
        _onlyOwner
    {
        _dataStorageAddress = dataStorageAddress;
    }

    /// @dev Changes the standard storage contract address
    function changeStandardStorageAddress(address standardStorageAddress)
        external
        _onlyOwner
    {
        _standardStorageAddress = standardStorageAddress;
    }

    /// @dev Changes the data validation contract address
    function changeDataValidationAddress(address dataValidationAddress)
        external
        _onlyOwner
    {
        _dataValidationAddress = dataValidationAddress;
    }

    /// @dev Changes the standard validation contract address
    function changeStandardValidationAddress(address standardValidationAddress)
        external
        _onlyOwner
    {
        _standardValidationAddress = standardValidationAddress;
    }

    // MARK: - External Storage Methods

    function storeData(
        address provider,
        uint256 standard,
        string memory payload
    ) external {
        Models.BasicData memory data = Models.BasicData(
            msg.sender,
            provider,
            standard,
            Models.encoded(payload),
            true
        );

        DataValidationLayer(_dataValidationAddress).validateAndMintData(data);

        return;
    }

    function storeStandard(string memory name, string memory schema) external {
        Models.BasicStandard memory standard = Models.BasicStandard(
            Models.encoded(name),
            Models.encoded(schema),
            true
        );

        StandardValidationLayer(_standardValidationAddress)
            .validateAndMintStandard(standard);

        return;
    }

    function burnData(uint256 token) external {
        Models.Data memory data = DataStorageLayer(_dataStorageAddress)
            .dataForToken(token);

        DataStorageLayer(_dataStorageAddress).burn(data);

        return;
    }

    function transferData(uint256 token, address to) external {
        DataStorageLayer(_dataStorageAddress).transfer(token, to);

        return;
    }

    // MARK: - External Fetch Methods

    function dataForToken(uint256 token)
        external
        view
        returns (Models.Data memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForToken(token);
    }

    function dataForOwner(address owner)
        external
        view
        returns (Models.Data[] memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForOwner(owner);
    }

    function dataForStandard(uint256 standard)
        external
        view
        returns (Models.Data[] memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForStandard(standard);
    }

    function dataForOwnerInStandard(address owner, uint256 standard)
        external
        view
        returns (Models.Data[] memory)
    {
        return
            DataStorageLayer(_dataStorageAddress).dataForOwnerInStandard(
                owner,
                standard
            );
    }

    function standardForToken(uint256 token)
        external
        view
        returns (Models.Standard memory)
    {
        return
            StandardStorageLayer(_standardStorageAddress).standardForToken(
                token
            );
    }

    function allStandards() external view returns (Models.Standard[] memory) {
        return StandardStorageLayer(_standardStorageAddress).allStandards();
    }
}
