//SPDX-License-Identifier: Unlicense
// Basin Data Store Contract
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import {Counters} from "./libraries/Counters.sol";
import {Base64} from "./libraries/Base64.sol";

// Basin Contract 0
contract BasinDataStore {
    // Contract owner
    address payable private basin;

    // Token Ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // New data event
    event NewData(Data data);

    // New Standard event
    event NewStandard(Standard standard);

    // Data map
    mapping(uint256 => Data) private data;

    // User data map
    mapping(address => uint256[]) private userData;

    // User Standard data map
    mapping(address => mapping(string => uint256[])) private userStandardData;

    // All provider data map
    mapping(address => uint256[]) private providerData;

    // Provider Standard data map
    mapping(address => mapping(string => uint256[])) private providerStandardData;

    // All Standard data map
    mapping(string => uint256[]) private standardData;

    // Standards array
    mapping(string => Standard) private standards;

    // Standard structure
    struct Standard {
        string id;
        string name;
        string conformance;
        bool exists;
    }

    // Data structure
    struct Data {
        uint256 id;
        address provider;
        address user;
        string standard;
        uint256 timestamp;
        string payload;
    }

    // Constrcutor
    constructor() payable {
        console.log("Basin contract constructed");

        basin = payable(msg.sender);
    }

    /// @notice Fetches all data for contract owner
    /// @dev Fetches all data. Private to contract owner
    function fetchAllData() public view returns (Data[] memory) {
        require(msg.sender == basin, "Must be contract owner");

        uint256 length = _tokenIds.current() - 2;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = data[i];
        }

        return result;
    }

    /// @notice Stores data in the on chain data structures
    /// @dev Create a data payload and store it in the available on chain data structures
    /// @param _provider the provider of the data - shared owner
    /// @param _user the owner of the data - shared owner
    /// @param _standard the Standard of the data
    /// @param _payload the data to be stored
    function storeData(
        address payable _provider,
        address payable _user,
        string memory _standard,
        string memory _payload
    ) public payable {
        string memory json = encodedPayload(_payload);

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
        providerStandardData[_user][_standard].push(_tokenIds.current());

        console.log("Data stored on chain at index:", _tokenIds.current());

        _tokenIds.increment();

        emit NewData(fullPayload);
    }

    /// @notice Fetches all user data for current address
    /// @dev Fetches all user data. Private to sender
    function fetchUserData() public view returns (Data[] memory) {
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
    function fetchDataForStandard(string memory _standard)
        public
        view
        returns (Data[] memory)
    {
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
    function fetchDataForUserInStandard(address _user, string memory _standard)
        public
        view
        returns (Data[] memory)
    {
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
    function fetchDataForProvider(address _provider, string memory _standard)
        public
        view
        returns (Data[] memory)
    {
        console.log("Fetching standard provider data for", _provider);

        uint256[] memory temp = providerStandardData[_provider][_standard];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = rawData(data[temp[i]]);
        }

        return result;
    }

    /// @notice Creates a new standard with conformance rules
    /// @dev Creates a new standard. Public
    function createStandard(
        string memory _id,
        string memory _name,
        string memory _conformance
    ) public {
        require(!standardExists(_id), "Standard already exists");

        // TODO - Add create standard logic
        Standard memory standard = Standard(_id, _name, _conformance, true);

        console.log("Created new standard: %s", _name);

        standards[_id] = standard;

        emit NewStandard(standard);
    }

    // MARK: - Standard Conformance

    /// @notice Checks payload against Standard conformance
    /// @dev Checks payload against Standard conformance. Private
    function conformsToStandard(string memory _payload, string memory _id)
        private
        view
        returns (bool)
    {
        require(standardExists(_id), "Standard must exist");

        Standard memory standard = standards[_id];

        string memory strippedPayload = stripPayload(_payload);

        return
            keccak256(bytes(standard.conformance)) ==
            keccak256(bytes(strippedPayload));
    }

    /// @dev Checks if Standard exists. Private
    function standardExists(string memory _id) private view returns (bool) {
        return standards[_id].exists;
    }

    // Mark: - Helpers

    /// @dev Gets the raw value
    function rawData(Data memory _fullPayload) private pure returns (Data memory) {
        Data memory newData = Data(
            _fullPayload.id,
            _fullPayload.provider,
            _fullPayload.user,
            _fullPayload.standard,
            _fullPayload.timestamp,
            decodedPayload(_fullPayload.payload)
        );

        return newData;
    }

    /// @dev Encodes payloads
    function encodedPayload(string memory _payload) private pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        _payload
                    )
                )
            )
        );

        return json;
    }

    /// @dev Decodes payloads to return raw values
    function decodedPayload(string memory _payload) private pure returns (string memory) {
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
