// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";

contract DataStore {
    using Counters for Counters.Counter;

    // Contract owner
    address payable private _contractOwner;

    // Token Ids for data
    Counters.Counter private _tokenIds;

    // Token Ids for standards
    Counters.Counter private _standardIds;

    // Data map
    mapping(uint256 => Data) private _data;

    // Standards map
    mapping(uint256 => Standard) private _standards;

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
    event NewData(Data data);

    // New Standard event
    event NewStandard(Standard standard);

    // Data structure
    struct Data {
        uint256 token;
        address owner;
        uint256 standard;
        uint256 timestamp;
        string payload;
    }

    // Standard structure
    struct Standard {
        uint256 token;
        string name;
        string schema;
        bool exists;
    }

    // MARK: - Contract Constructor

    // Constrcutor
    constructor() payable {
        console.log("DataStore contract constructed by %s", msg.sender);
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
    function changeOwner(address payable newOwner) public _onlyOwner {
        _contractOwner = newOwner;
    }

    // MARK: - Minters

    /// @dev Mints data to the contract
    function _mintData(Data memory data) private {
        require(_isValidData(data), "Data is invalid.");

        // TODO - Sign transaction via Basin
        // require(basin.sign(), 'Failed to sign')

        // Writes data to contract
        _data[data.token] = data;
        _dataOwners[data.token] = data.owner;
        _dataStandards[data.token] = data.standard;

        // Increments balances
        _ownerBalances[data.owner]++;
        _standardBalances[data.standard]++;
        _ownerStandardBalances[data.owner][data.standard]++;
    }

    /// @dev Mints a standard to the contract
    function _mintStandard(Standard memory standard) private {
        require(!_standardExists(standard.token), "Standard already exists.");

        // TODO - Sign transaction via Basin
        // require(basin.sign(), 'Failed to sign')

        _standards[standard.token] = standard;
    }

    /// @dev Burns data from contract
    function _burnData(Data memory data) private {
        require(_tokenExists(data.token), "Data is invalid.");
        require(_validOwner(msg.sender), "Owner address is invalid.");
        require(_isOwner(msg.sender, data.token), "Owner is invalid.");

        // TODO - Sign transaction via Basin
        // require(basin.sign(), 'Failed to sign')

        // Increments balances
        _ownerBalances[data.owner]--;
        _standardBalances[data.standard]--;
        _ownerStandardBalances[data.owner][data.standard]--;

        // Removes owners from data
        delete _dataOwners[data.token];
        delete _dataStandards[data.token];
    }

    // MARK: - Transfer methods

    function _transferData(address to, Data memory data) private {
        require(_tokenExists(data.token), "Data does not exists.");
        require(_validOwner(msg.sender), "Owner address is invalid.");
        require(_isOwner(msg.sender, data.token), "Owner is invalid.");
        require(_validOwner(to), "Destination address is invalid.");

        // TODO - Sign transaction via Basin
        // require(basin.sign(), 'Failed to sign')

        _data[data.token].owner = to;
        _dataOwners[data.token] = to;

        _ownerBalances[to]++;
        _ownerBalances[msg.sender]--;
    }

    // MARK: - Public Write Methods

    /// @dev Stores data in the on chain data structures
    function storeData(
        address owner,
        uint256 standard,
        string memory payload
    ) public _onlyOwner {
        string memory obj = encoded(payload);

        Data memory data = Data(
            _tokenIds.current(),
            owner,
            standard,
            block.timestamp,
            obj
        );

        console.log("owner: '%s'", owner);
        console.log("standard: '%s'", standard);
        console.log("payload: '%s'", payload);

        _mintData(data);

        console.log("Data stored on chain at index:", _tokenIds.current());

        _tokenIds.increment();

        emit NewData(rawData(data));
    }

    /// @dev Creates a new standard. Public
    function createStandard(string memory name, string memory schema)
        public
        _onlyOwner
    {
        string memory encodedName = encoded(name);

        bytes32 byteName = keccak256(bytes(encodedName));

        require(!standardNameExists(byteName), "Standard name already exists");

        string memory encodedSchema = encoded(schema);

        Standard memory standard = Standard(
            _standardIds.current(),
            encodedName,
            encodedSchema,
            true
        );

        _mintStandard(standard);

        _standardIds.increment();

        console.log("Created new standard: %s", name);

        emit NewStandard(rawStandard(standard));
    }

    // MARK: - Fetch methods

    function dataForOwner(address owner) public view returns (Data[] memory) {
        require(_validOwner(owner), "Owner is not valid.");

        uint256 balance = _ownerBalances[owner];
        Data[] memory result = new Data[](balance);

        uint256 counter = 0;
        for (uint256 i = 0; i < balance; i += 1) {
            if (owner == _dataOwners[i]) {
                result[counter] = rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    function dataForStandard(uint256 standard)
        public
        view
        returns (Data[] memory)
    {
        require(_standardExists(standard), "Standard does not exist.");

        uint256 balance = _standardBalances[standard];
        Data[] memory result = new Data[](balance);

        uint256 counter = 0;
        for (uint256 i = 0; i < balance; i += 1) {
            if (standard == _dataStandards[i]) {
                result[counter] = rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    function dataForOwnerInStandard(address owner, uint256 standard)
        public
        view
        returns (Data[] memory)
    {
        require(_validOwner(owner), "Owner is not valid.");
        require(_standardExists(standard), "Standard does not exist.");

        uint256 balance = _ownerStandardBalances[owner][standard];
        Data[] memory result = new Data[](balance);

        uint256 counter = 0;
        for (uint256 i = 0; i < balance; i += 1) {
            if (owner == _dataOwners[i] && standard == _dataStandards[i]) {
                result[counter] = rawData(_data[i]);
                counter++;
            }
        }

        return result;
    }

    function allStandards() public view returns (Standard[] memory) {
        uint256 length = _standardIds.current();
        Standard[] memory result = new Standard[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawStandard(_standards[i]);
        }

        return result;
    }

    function _isValidData(Data memory data) private view returns (bool) {
        return
            _validOwner(data.owner) &&
            !_tokenExists(data.token) &&
            _standardExists(data.standard);
    }

    function _validOwner(address owner) private pure returns (bool) {
        return owner != address(0);
    }

    function _tokenExists(uint256 tokenId) private view returns (bool) {
        return _dataOwners[tokenId] != address(0);
    }

    function _standardExists(uint256 standardId) private view returns (bool) {
        return standardId < _standardIds.current();
    }

    /// @dev Checks if Standard name exists. Private
    function standardNameExists(bytes32 name) private view returns (bool) {
        for (uint256 i = 0; i < _standardIds.current(); i += 1) {
            bytes32 byteName = keccak256(bytes(_standards[i].name));
            if (name == byteName) {
                return true;
            }
        }

        return false;
    }

    function _isOwner(address owner, uint256 token)
        private
        view
        returns (bool)
    {
        return owner == _dataOwners[token];
    }

    // MARK: - Helpers

    /// @dev Gets the raw standard
    function rawStandard(Standard memory standard)
        private
        pure
        returns (Standard memory)
    {
        Standard memory newStandard = Standard(
            standard.token,
            decoded(standard.name),
            decoded(standard.schema),
            standard.exists
        );

        return newStandard;
    }

    /// @dev Gets the raw value
    function rawData(Data memory data) private pure returns (Data memory) {
        Data memory newData = Data(
            data.token,
            data.owner,
            data.standard,
            data.timestamp,
            decoded(data.payload)
        );

        return newData;
    }

    /// @dev Encodes
    function encoded(string memory _payload)
        private
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
        private
        pure
        returns (string memory)
    {
        bytes memory rawPayload = Base64.decode(_payload);

        return string(rawPayload);
    }
}
