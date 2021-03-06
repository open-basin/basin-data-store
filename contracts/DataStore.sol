// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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

    // Contract bank
    address payable private _bank;

    // Standard Fee
    uint256 private _standardFee;

    // Data Fee
    uint256 private _dataFee;

    // Provider Fee
    uint256 private _providerFee;

    // Transfer Fee
    uint256 private _transferFee;

    // Data Storage Contract Address
    address private _dataStorageAddress;

    // Standard Storage Contract Address
    address private _standardStorageAddress;

    // Data Validation Contract Address
    address private _dataValidationAddress;

    // Standard Validation Contract Address
    address private _standardValidationAddress;

    // New Standard Event
    event NewStandard(uint256 indexed token);

    // New Data Event
    event NewData(uint256 indexed token);

    // New data transfer event
    event NewTransfer(
        uint256 token,
        address indexed to,
        address indexed from,
        uint256 indexed standard
    );

    // New data burn event
    event NewBurn(
        uint256 indexed token,
        address indexed owner,
        uint256 indexed standard
    );

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

    /// @dev Contract fallback method
    fallback() external {
        console.log("DataStore Transaction failed.");
    }

    /// @dev Checks if the signer is the contract owner
    modifier _onlyOwner() {
        require(msg.sender == _contractOwner, "Must be contract owner.");
        _;
    }

    // @dev Checks if the signer is the contract bank
    modifier _onlyBank() {
        require(msg.sender == _bank, "Must be bank.");
        _;
    }

    /// @dev Changes contract owner
    function changeOwner(address payable newOwner) external _onlyOwner {
        _contractOwner = newOwner;
    }

    /// @dev Changes contract bank
    function changeBank(address payable newBank) external _onlyOwner {
        _bank = newBank;
    }

    /// @dev Changes contract fees
    function changeFees(
        uint256 standardFee,
        uint256 dataFee,
        uint256 transferFee,
        uint256 providerFee
    ) external _onlyOwner {
        _standardFee = standardFee;
        _dataFee = dataFee;
        _transferFee = transferFee;
        _providerFee = providerFee;
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

    /// @dev Creates a new standard in standard storage
    function createStandard(string memory name, string memory schema)
        external
        payable
    {
        require(msg.value >= _standardFee, "Must have value.");

        Models.BasicStandard memory standard = Models.BasicStandard(
            msg.sender,
            Models.encoded(name),
            Models.encoded(schema)
        );

        uint256 token = StandardValidationLayer(_standardValidationAddress)
            .validateAndMintStandard(standard);

        // Pay bank
        _distribute(_bank, _standardFee);

        emit NewStandard(token);
    }

    /// @dev Stores a data in data storage
    function storeData(
        address provider,
        uint256 standard,
        string memory payload
    ) external payable {
        require(msg.value >= (_providerFee + _dataFee), "Must have value");

        Models.BasicData memory data = Models.BasicData(
            msg.sender,
            provider,
            standard,
            Models.encoded(payload)
        );

        uint256 token = DataValidationLayer(_dataValidationAddress)
            .validateAndMintData(data);

        // Pay bank and provider
        _distribute(payable(data.provider), _providerFee);
        _distribute(_bank, _dataFee);

        emit NewData(token);
    }

    /// @dev Burns data from storage
    function burnData(uint256 token) external payable {
        Models.Data memory data = DataStorageLayer(_dataStorageAddress)
            .dataForToken(token);

        DataStorageLayer(_dataStorageAddress).burn(data);

        emit NewBurn(token, data.owner, data.standard);
    }

    /// @dev Transfers data to address
    function transferData(uint256 token, address to) external payable {
        require(msg.value >= _transferFee, "Must have value");

        DataStorageLayer(_dataStorageAddress).transfer(token, to);

        // Pay bank
        _distribute(_bank, _transferFee);

        Models.Data memory data = DataStorageLayer(_dataStorageAddress)
            .dataForToken(token);

        emit NewTransfer(token, to, msg.sender, data.standard);
    }

    // MARK: - External Fetch Methods

    /// @dev Fetches data for a token
    function dataForToken(uint256 token)
        external
        view
        returns (Models.Data memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForToken(token);
    }

    /// @dev Fetches all data for an owner
    function dataForOwner(address owner)
        external
        view
        returns (Models.Data[] memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForOwner(owner);
    }

    /// @dev Fetches all data for a provider
    function dataForProvider(address provider)
        external
        view
        returns (Models.Data[] memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForProvider(provider);
    }

    /// @dev Fetches all data for a standard
    function dataForStandard(uint256 standard)
        external
        view
        returns (Models.Data[] memory)
    {
        return DataStorageLayer(_dataStorageAddress).dataForStandard(standard);
    }

    /// @dev Fetches all data for an owner in a standard
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

    /// @dev Fetches standard for a token
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

    /// @dev Fetches all fulfilled standards
    function allStandards() external view returns (Models.Standard[] memory) {
        return StandardStorageLayer(_standardStorageAddress).allStandards();
    }

    /// @dev Fetches all standards for a minter
    function standardsForMinter(address minter)
        external
        view
        returns (Models.Standard[] memory)
    {
        return
            StandardStorageLayer(_standardStorageAddress).standardsForMinter(
                minter
            );
    }

    // MARK: - Distribute Methods

    function _distribute(address payable to, uint256 amount) private {
        require(msg.value > 0);
        to.transfer(amount);
    }

    function _collect(uint256 amount) external _onlyBank {
        _bank.transfer(amount);
    }

    // MARK: - Helpers

    function _validAddress(address adr) private pure returns (bool) {
        return adr != address(0);
    }
}
