// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ActivitiesHall {

    string public name;
    address[] public activities;
    event NewActivity(address newActivityAddress, string name, address creator);

    constructor(string memory _name) {
        name = _name;
    }

    function deployActivity(string memory _name, uint _stakeFee, address _tokenUsed, uint _availableTimeForConsensus) external {
        address newActivity = address(new Activity(_name, _availableTimeForConsensus, _stakeFee, _tokenUsed, msg.sender));
        activities.push(newActivity);
        emit NewActivity(newActivity,_name, msg.sender);
    }


}

contract Activity {

    using SafeERC20 for IERC20;

    string public name;
    address public creator;
    address public tokenUsed;

    uint minNumberOfPlayer;
    uint stakeFee;

    struct LocationAndTime {
        uint locationId;
        uint dateId;
        uint positiveVoteNumber;
    }

    // Best Location and time updated with each vote
    LocationAndTime public bestLocationAndTime;

    uint public endingTimeForConsensus;
    bool public consensusReached;
    bool public voteResultGiven;

    mapping(address => bool) public ActivityMembers;
    mapping(uint => Location) public locationsProposed;


    uint public locationCursor;

    event NewLocation(uint locationId, string name);
    event NewVote(address voter, uint locationId, VoteOption[] vote);
    event NewMember(address newMember);
    event NewDateProposed(uint locationId, Date dateProposed);
    event AmountSentBackToUser(address user, uint amount);
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
        mapping(uint => Date) datesProposed;
        mapping(uint => DateVotes) datesProposedVotes;
        uint datesCursor;
        mapping(address => bool) votingUsers;
    }

    constructor(string memory _name, uint _availableTimeForConsensus, uint _stakeFee, address _tokenUsed, address _creator) {
        name = _name;
        endingTimeForConsensus = block.timestamp + _availableTimeForConsensus;
        locationCursor = 0;
        stakeFee = _stakeFee;
        tokenUsed = _tokenUsed;
        creator = _creator;
        ActivityMembers[creator] = true;
        consensusReached = false;
        voteResultGiven = false;
        bestLocationAndTime = LocationAndTime(0, 0, 0);
    }

    modifier isVotePossible(){
        require(block.timestamp < endingTimeForConsensus, "Vote is no more possible");
        _;
    }

    modifier isVoteFinished() {
        require(block.timestamp >= endingTimeForConsensus, "Vote is not closed");
        _;
    }

    modifier isVoteFinishedAndResultGiven() {
        require(block.timestamp >= endingTimeForConsensus, "Vote is not closed");
        require(voteResultGiven, "Need to call getResultVoting first");
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
        uint i;
        for (i = 0; i < datesProposed.length; i++){
            newLocation.datesProposed[i] = datesProposed[i];
        }
        newLocation.datesCursor = i;
        locationCursor += 1;
        emit NewLocation(locationCursor - 1, _name);
    }

    function addDateToExistingLocation(uint _locationId, Date memory dateProposed) external isLocationIdValid(_locationId) isUserMember isVotePossible {
        Location storage location = locationsProposed[_locationId];
        location.datesProposed[location.datesCursor] = dateProposed;
        location.datesCursor += 1;
        emit NewDateProposed(_locationId, dateProposed);
    }

    function vote(uint _locationId, VoteOption[] memory userVotes) external isLocationIdValid(_locationId) isVotePossible isUserMember canUserVote(_locationId) {
        Location storage location = locationsProposed[_locationId];

        // Send the tokens to stake, they need to be approved before
        IERC20(tokenUsed).safeTransferFrom(msg.sender,address(this), stakeFee);

        for (uint i = 0; i < location.datesCursor; i++ ) {
            VoteOption userVote = userVotes[i];
            if (userVote == VoteOption.ACCEPT) {
                location.datesProposedVotes[i].positiveVoteNumber += 1;
                uint positiveVoteNumber = location.datesProposedVotes[i].positiveVoteNumber;
                if (positiveVoteNumber > bestLocationAndTime.positiveVoteNumber) {
                    bestLocationAndTime.dateId = i;
                    bestLocationAndTime.locationId = _locationId;
                    bestLocationAndTime.positiveVoteNumber = positiveVoteNumber;
                }
            }
            else {
                location.datesProposedVotes[i].negativeVoteNumber += 1;
            }
            location.datesProposedVotes[i].totalVoteNumber += 1;
        }

        location.votingUsers[msg.sender] = true;
        
        emit NewVote(msg.sender, _locationId, userVotes);
    }

    
    function getResultVoting() external isVoteFinished {
        if (bestLocationAndTime.positiveVoteNumber >= minNumberOfPlayer){
            consensusReached = true;
        }
        else {
            consensusReached = false;
        }
        voteResultGiven = true;
    }

    function claimUnusedStaking() external isVoteFinishedAndResultGiven isUserMember{
        uint amountToSendBack = 0;
        // If consensus is reached user can claim his stake for all Location voting EXCEPT the chosen one
        if (consensusReached){
            uint chosenLocationId = bestLocationAndTime.locationId;
            for (uint i = 0; i < locationCursor; i++) {
                if (i != chosenLocationId) {
                    amountToSendBack += stakeFee;
                }
            }
        }

        // If consensus is NOT reached user can claim his stake for all Location voting INCLUDING the chosen one
        else {
            for (uint i = 0; i < locationCursor; i++) {
                amountToSendBack += stakeFee;
            }
        }

        // We send back the token amount back to the user
        if (amountToSendBack > 0){
            IERC20(tokenUsed).safeTransfer(msg.sender,amountToSendBack);
            emit AmountSentBackToUser(msg.sender, amountToSendBack);
        }
    }
    

}