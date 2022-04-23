// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ActivitiesHall {

    string public name;
    address[] public activities;
    event NewActivity(address newActivityAddress, string name, address creator);

    constructor(string memory _name) {
        name = _name;
    }

    function deployActivity(string memory _name, uint _availableTimeForConsensus) external {
        address newActivity = address(new Activity(_name, _availableTimeForConsensus, msg.sender));
        activities.push(newActivity);
        emit NewActivity(newActivity,_name, msg.sender);
    }


}

contract Activity {

    string public name;
    address public creator;

    uint public endingTimeForConsensus;

    mapping(address => bool) public ActivityMembers;
    mapping(uint => Location) public locationsProposed;

    uint public locationCursor;

    event NewLocation(uint locationId, string name);
    event NewVote(address voter, uint locationId, VoteOption[] vote);
    event NewMember(address newMember);
    event NewDateProposed(uint locationId, Date dateProposed);

    enum VotingStatus {
        PENDING,
        ACCEPTED,
        REJECTED
    }

    enum VoteOption {
        ACCEPT,
        REJECT
    }

    struct Date {
        uint timestamp;
    }

    struct DateVotes {
        uint positiveVoteNumber;
        uint negativeVoteNumber;
        uint totalVoteNumber;
    }

    struct Location {
        string name;
        address proposer;
        VotingStatus status;
        mapping(uint => Date) datesProposed;
        mapping(uint => DateVotes) datesProposedVotes;
        uint datesCursor;
        mapping(address => bool) votingUsers;
    }

    constructor(string memory _name, uint _availableTimeForConsensus, address _creator) {
        name = _name;
        endingTimeForConsensus = block.timestamp + _availableTimeForConsensus;
        locationCursor = 0;
        creator = _creator;
        ActivityMembers[creator] = true;
    }

    modifier isVotePossible(uint _locationId){
        require(block.timestamp < endingTimeForConsensus, "Vote is no more possible");
        _;
    }

    modifier canUserVote(uint _locationId) {
        // Check if the user has already voted in the location
        require(!locationsProposed[_locationId].votingUsers[msg.sender], "Already voted");
        _;
    }

    modifier isUserMember() {
        // Check if user is a member of the Activity
        require(ActivityMembers[msg.sender], "Not a Activity member");
        _;
    }

    modifier isLocationIdValid(uint _locationId) {
        // Check if _locationId points to an existing location
        require(_locationId < locationCursor, "LocationId invalid");
        _;
    }

    /// @notice Manage who can enter the Activity
    /// @dev very simple for now needs to be implemented
    function joinActivity() external {
        ActivityMembers[msg.sender] = true;
        emit NewMember(msg.sender);
    }


    function proposeLocation(string memory _name, Date[] memory datesProposed) external isUserMember {
        Location storage newLocation = locationsProposed[locationCursor];
        newLocation.name = _name;
        newLocation.proposer = msg.sender;
        newLocation.status = VotingStatus.PENDING;
        uint i;
        for (i = 0; i < datesProposed.length; i++){
            newLocation.datesProposed[i] = datesProposed[i];
        }
        newLocation.datesCursor = i;
        locationCursor += 1;
        emit NewLocation(locationCursor - 1, _name);
    }

    function addDateToExistingLocation(uint _locationId, Date memory dateProposed) external isLocationIdValid(_locationId) isUserMember isVotePossible(_locationId) {
        Location storage location = locationsProposed[_locationId];
        location.datesProposed[location.datesCursor] = dateProposed;
        location.datesCursor += 1;
        emit NewDateProposed(_locationId, dateProposed);
    }

    function vote(uint _locationId, VoteOption[] memory userVotes) external isLocationIdValid(_locationId) isVotePossible(_locationId) isUserMember canUserVote(_locationId) {
        Location storage location = locationsProposed[_locationId];

        require(location.status == VotingStatus.PENDING, "Vote is closed");
        for (uint i = 0; i < location.datesCursor; i++ ) {
            VoteOption userVote = userVotes[i];
            if (userVote == VoteOption.ACCEPT) {
                location.datesProposedVotes[i].positiveVoteNumber += 1;
            }
            else {
                location.datesProposedVotes[i].negativeVoteNumber += 1;
            }
            location.datesProposedVotes[i].totalVoteNumber += 1;
        }

        location.votingUsers[msg.sender] = true;
        
        emit NewVote(msg.sender, _locationId, userVotes);
    }

    

    

}