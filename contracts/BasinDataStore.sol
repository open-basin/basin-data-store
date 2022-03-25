//SPDX-License-Identifier: Unlicense
// Basin Data Store Contract
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";

// Basin Contract 0
contract BasinDataStore {
    // MARK: - Contract Properties

    // Contract owner
    address payable private basin;

    // Contract life state
    bool private destroyed = false;

    // Contract enabled state
    bool private enabled = true;

    // Token Ids for data
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Token Ids for standards
    using Counters for Counters.Counter;
    Counters.Counter private _standardIds;

    // New data event
    event NewData(Data data);

    // New Standard event
    event NewStandard(Standard standard);

    // Data map
    mapping(uint256 => Data) private data;

    // User data map
    mapping(address => uint256[]) private userData;

    // User Standard data map
    mapping(address => mapping(uint256 => uint256[])) private userStandardData;

    // All provider data map
    mapping(address => uint256[]) private providerData;

    // Provider Standard data map
    mapping(address => mapping(uint256 => uint256[]))
        private providerStandardData;

    // All Standard data map
    mapping(uint256 => uint256[]) private standardData;

    // Standards array
    mapping(uint256 => Standard) private standards;

    // Standard structure
    struct Standard {
        uint256 id;
        string name;
        string schema;
        bool exists;
    }

    // Data structure
    struct Data {
        uint256 id;
        address provider;
        address user;
        uint256 standard;
        uint256 timestamp;
        string payload;
    }

    // MARK: - Contract Constructor

    // Constrcutor
    constructor() payable {
        console.log("Basin contract constructed");

        basin = payable(msg.sender);
    }

    // MARK: - Contract Controls

    /// @dev Turns the contract off.. for good
    function destroy() public payable {
        require(!destroyed, "Contract is destroyed");
        ownerCheckpoint();

        enabled = false;
        destroyed = true;
    }

    /// @dev Turns the contract off
    function turnOff() public payable {
        require(!destroyed, "Contract is destroyed");
        ownerCheckpoint();

        enabled = false;
    }

    /// @dev Turns the contract on
    function turnOn() public payable {
        require(!destroyed, "Contract is destroyed");
        ownerCheckpoint();

        enabled = true;
    }

    /// @dev Checks if the contract can be accessed
    function contractCheckpoint() private view {
        require(!destroyed, "Contract is destroyed");
        require(enabled, "Contract is disabled");
    }

    /// @dev Checks if the signer is the contract owner
    function ownerCheckpoint() private view {
        require(msg.sender == basin, "Must be contract owner");
    }

    // MARK: - Write Methods

    /// @notice Stores data in the on chain data structures
    /// @dev Create a data payload and store it in the available on chain data structures
    /// @param _provider the provider of the data - shared owner
    /// @param _user the owner of the data - shared owner
    /// @param _standard the Standard of the data
    /// @param _payload the data to be stored
    function storeData(
        address payable _provider,
        address payable _user,
        uint256 _standard,
        string memory _payload
    ) public payable {
        contractCheckpoint();

        string memory json = encoded(_payload);

        Data memory fullPayload = Data(
            _tokenIds.current(),
            _provider,
            _user,
            _standard,
            block.timestamp,
            json
        );

        console.log("user: '%s'", _user);
        console.log("provider: '%s'", _provider);
        console.log("standard: '%s'", _standard);
        console.log("payload: '%s'", _payload);

        console.log("encoded: %s", json);

        data[_tokenIds.current()] = fullPayload;

        userData[_user].push(_tokenIds.current());
        providerData[_provider].push(_tokenIds.current());
        standardData[_standard].push(_tokenIds.current());

        userStandardData[_user][_standard].push(_tokenIds.current());
        providerStandardData[_provider][_standard].push(_tokenIds.current());

        console.log("Data stored on chain at index:", _tokenIds.current());

        _tokenIds.increment();

        emit NewData(fullPayload);
    }

    // MARK: - Read Methods

    /// @notice Fetches all data for contract owner
    /// @dev Fetches all data. Private to contract owner
    function fetchAllData() public view returns (Data[] memory) {
        contractCheckpoint();
        ownerCheckpoint();

        uint256 length = _tokenIds.current();
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = data[i];
        }

        return result;
    }

    /// @notice Fetches current standard token
    /// @dev Fetches current standard tokenId
    function fetchCurrentStandardToken() public view returns (uint256) {
        contractCheckpoint();
        ownerCheckpoint();

        return _standardIds.current();
    }

    /// @notice Fetches current token
    /// @dev Fetches current tokenId
    function fetchCurrentToken() public view returns (uint256) {
        contractCheckpoint();
        ownerCheckpoint();

        return _tokenIds.current();
    }

    /// @notice Fetches the standard for a given id
    /// @dev Fetches the standard for a given id
    function fetchStandard(uint256 _id) public view returns (Standard memory) {
        contractCheckpoint();

        require(standardExists(_id), "Standard must exist");

        return rawStandard(standards[_id]);
    }

    /// @notice Fetches all standards for contract owner
    /// @dev Fetches all standards. Private to contract owner
    function fetchAllStandards() public view returns (Standard[] memory) {
        contractCheckpoint();

        uint256 length = _standardIds.current();
        Standard[] memory result = new Standard[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawStandard(standards[i]);
        }

        return result;
    }

    /// @notice Fetches all user data for current address
    /// @dev Fetches all user data. Private to sender
    function fetchUserData() public view returns (Data[] memory) {
        contractCheckpoint();

        console.log("Fetching user data for", msg.sender);

        uint256[] memory temp = userData[msg.sender];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Fetches all provider data for current address
    /// @dev Fetches all provider data. Private to sender
    function fetchProviderData() public view returns (Data[] memory) {
        contractCheckpoint();

        console.log("Fetching provider data for", msg.sender);

        uint256[] memory temp = providerData[msg.sender];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Fetches all user data for user address
    /// @dev Fetches all user data. Public
    function fetchDataForUser(address _user)
        public
        view
        returns (Data[] memory)
    {
        contractCheckpoint();

        console.log("Fetching user data for", _user);

        uint256[] memory temp = userData[_user];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Fetches all provider data for provider
    /// @dev Fetches all provider data. Public
    function fetchDataForProvider(address _provider)
        public
        view
        returns (Data[] memory)
    {
        contractCheckpoint();

        console.log("Fetching provider data for", _provider);

        uint256[] memory temp = providerData[_provider];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Fetches all Standard data for Standard
    /// @dev Fetches all Standard data. Public
    function fetchDataForStandard(uint256 _standard)
        public
        view
        returns (Data[] memory)
    {
        contractCheckpoint();

        console.log("Fetching standard data for", _standard);

        uint256[] memory temp = standardData[_standard];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Fetches all user data for user in a standard
    /// @dev Fetches all user data in a standard. Public
    function fetchDataForUserInStandard(address _user, uint256 _standard)
        public
        view
        returns (Data[] memory)
    {
        contractCheckpoint();

        console.log("Fetching standard user data for", _user);

        uint256[] memory temp = userStandardData[_user][_standard];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Fetches all provider data for provider in user
    /// @dev Fetches all provider data in a standard. Public
    function fetchDataForProviderInStandard(
        address _provider,
        uint256 _standard
    ) public view returns (Data[] memory) {
        contractCheckpoint();

        console.log("Fetching standard provider data for", _provider);

        uint256[] memory temp = providerStandardData[_provider][_standard];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Creates a new standard with schema
    /// @dev Creates a new standard. Public
    function createStandard(string memory _name, string memory _schema)
        public
        returns (Standard memory)
    {
        contractCheckpoint();

        bytes memory name = bytes(_name);

        bytes32 byteName = keccak256(name);

        require(!standardNameExists(byteName), "Standard name already exists");

        string memory encodedName = encoded(_name);

        string memory encodedSchema = encoded(_schema);

        // TODO - Add create standard logic
        Standard memory standard = Standard(
            _standardIds.current(),
            encodedName,
            encodedSchema,
            true
        );

        console.log("Created new standard: %s", _name);

        standards[_standardIds.current()] = standard;

        _standardIds.increment();

        emit NewStandard(standard);

        return standard;
    }

    // MARK: - Standard Conformance

    /// @notice Checks payload against Standard schema
    /// @dev Checks payload against Standard schema. Private
    function conformsToStandard(string memory _payload, uint256 _id)
        private
        view
        returns (bool)
    {
        require(standardExists(_id), "Standard must exist");

        Standard memory standard = standards[_id];

        string memory strippedPayload = stripPayload(_payload);

        return
            keccak256(bytes(standard.schema)) ==
            keccak256(bytes(strippedPayload));
    }

    /// @dev Gets standard id from name
    function standardId(bytes32 _name) public view returns (uint256) {
        for (uint256 i = 0; i < _standardIds.current(); i += 1) {
            bytes32 byteName = keccak256(bytes(standards[i].name));
            if (byteName == byteName) {
                return i;
            }
        }

        require(false, "Standard does not exist");

        return 0;
    }

    /// @dev Checks if Standard exists. Private
    function standardExists(uint256 _id) private view returns (bool) {
        return _id < _standardIds.current();
    }

    /// @dev Checks if Standard name exists. Private
    function standardNameExists(bytes32 _name) private view returns (bool) {
        for (uint256 i = 0; i < _standardIds.current(); i += 1) {
            bytes32 byteName = keccak256(bytes(standards[i].name));
            if (_name == byteName) {
                return true;
            }
        }

        return false;
    }

    // Mark: - Helpers

    /// @dev Gets the raw standard
    function rawStandard(Standard memory _standard)
        private
        pure
        returns (Standard memory)
    {
        Standard memory standard = Standard(
            _standard.id,
            decoded(_standard.name),
            decoded(_standard.schema),
            _standard.exists
        );

        return standard;
    }

    /// @dev Gets the raw value
    function rawData(Data memory _fullPayload)
        private
        pure
        returns (Data memory)
    {
        Data memory newData = Data(
            _fullPayload.id,
            _fullPayload.provider,
            _fullPayload.user,
            _fullPayload.standard,
            _fullPayload.timestamp,
            decoded(_fullPayload.payload)
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

    /// @dev Strips the payload of values
    function stripPayload(string memory _payload)
        private
        view
        returns (string memory)
    {
        // TODO - strip out value and leave keys
        // https://medium.com/aventus/working-with-strings-in-solidity-473bcc59dc04

        return "";
    }
}
