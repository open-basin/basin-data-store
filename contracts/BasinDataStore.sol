//SPDX-License-Identifier: Unlicense
// Basin Data Store Contract
pragma solidity ^0.8.0;

import "hardhat/console.sol";

// Basin Contract 0
contract BasinDataStore {
    // Contract owner
    address payable private basin;

    // Current data index
    uint256 private currentIndex;

    // New data event
    event NewData(Data data);

    // New group event
    event NewGroup(Group group);

    // Data map
    mapping(uint256 => Data) private data;

    // User data map
    mapping(address => uint256[]) private userData;

    // User group data map
    mapping(address => mapping(string => uint256[])) private userGroupData;

    // All provider data map
    mapping(address => uint256[]) private providerData;

    // Provider group data map
    mapping(address => mapping(string => uint256[])) private providerGroupData;

    // All group data map
    mapping(string => uint256[]) private groupData;

    // Groups array
    mapping(string => Group) private groups;

    // Group structure
    struct Group {
        string id;
        string name;
        string conformance;
        bool exists;
    }

    // Data structure
    struct Data {
        address provider;
        address user;
        string group;
        uint256 timestamp;
        string payload;
    }

    // Constrcutor
    constructor() payable {
        console.log("Basin contract constructed");

        basin = payable(msg.sender);

        currentIndex = 0;
    }

    /// @notice Fetches all data for contract owner
    /// @dev Fetches all data. Private to contract owner
    function fetchAllData() public view returns (Data[] memory) {
        require(msg.sender == basin, "Must be contract owner");

        uint256 length = currentIndex - 2;
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
    /// @param _group the group of the data
    /// @param _payload the data to be stored
    function storeData(
        address payable _provider,
        address payable _user,
        string memory _group,
        string memory _payload
    ) public payable {
        require(conformsToGroup(_payload, _group), "Data must conform to group");

        Data memory fullPayload = Data(
            _provider,
            _user,
            _group,
            block.timestamp,
            _payload
        );

        console.log("user: '%s'", _user);
        console.log("provider: '%s'", _provider);
        console.log("group: '%s'", _group);
        console.log("payload: '%s'", _payload);

        data[currentIndex] = fullPayload;

        userData[_user].push(currentIndex);
        providerData[_provider].push(currentIndex);
        groupData[_group].push(currentIndex);

        userGroupData[_user][_group].push(currentIndex);
        providerGroupData[_user][_group].push(currentIndex);

        console.log("Data stored on chain at index:", currentIndex);

        currentIndex += 1;

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
            result[i] = data[temp[i]];
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
            result[i] = data[temp[i]];
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
            result[i] = data[temp[i]];
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
            result[i] = data[temp[i]];
        }

        return result;
    }

    /// @notice Fetches all group data for group
    /// @dev Fetches all group data. Public
    function fetchDataForGroup(string memory _group)
        public
        view
        returns (Data[] memory)
    {
        console.log("Fetching group data for", _group);

        uint256[] memory temp = groupData[_group];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = data[temp[i]];
        }

        return result;
    }

    /// @notice Fetches all user data for user in a group
    /// @dev Fetches all user data in a group. Public
    function fetchDataForUserInGroup(address _user, string memory _group)
        public
        view
        returns (Data[] memory)
    {
        console.log("Fetching group user data for", _user);

        uint256[] memory temp = userGroupData[_user][_group];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = data[temp[i]];
        }

        return result;
    }

    /// @notice Fetches all provider data for provider in user
    /// @dev Fetches all provider data in a group. Public
    function fetchDataForProvider(address _provider, string memory _group)
        public
        view
        returns (Data[] memory)
    {
        console.log("Fetching group provider data for", _provider);

        uint256[] memory temp = providerGroupData[_provider][_group];
        uint256 length = temp.length;
        Data[] memory result = new Data[](length);

        for (uint256 i = 0; i < length; i += 1) {
            result[i] = data[temp[i]];
        }

        return result;
    }

        /// @notice Creates a new group with conformance rules
    /// @dev Creates a new group. Public
    function createGroup(
        string memory _id,
        string memory _name,
        string memory _conformance
    ) public {
        require(!groupExists(_id), "Group already exists");

        // TODO - Add create group logic
        Group memory group = Group(_id, _name, _conformance, true);

        console.log("Created new group: %s", _name);

        groups[_id] = group;

        emit NewGroup(group);
    }

    /// @notice Checks payload against group conformance
    /// @dev Checks payload against group conformance. Private
    function conformsToGroup(string memory _payload, string memory _id)
        private
        view
        returns (bool)
    {
        require(groupExists(_id), "Group must exist");

        Group memory group = groups[_id];

        string memory strippedPayload = stripPayload(_payload);

        return keccak256(bytes(group.conformance)) == keccak256(bytes(strippedPayload));
    }

    function stripPayload(string memory _payload) private view returns (string memory) {
        // TODO - strip out value and leave keys
        // https://medium.com/aventus/working-with-strings-in-solidity-473bcc59dc04

        return "";
    }

    /// @dev Checks if group exists. Private
    function groupExists(string memory _id) private view returns (bool) {
        return groups[_id].exists;
    }
}
