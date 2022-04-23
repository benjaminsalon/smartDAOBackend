// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ActivitiesHall {

    string public name;
    address[] public activities;
    event NewActivity(address newActivityAddress, string name);

    constructor(string memory _name) {
        name = _name;
    }

    function deployActivity(string memory _name) external {
        address newActivity = address(new Activity(_name));
        activities.push(newActivity);
        emit NewActivity(newActivity,_name);
    }


}

contract Activity {

    string public name;

    mapping(address => bool) public ActivityMembers;
    mapping(uint => Proposal) public placesProposed;

    uint public proposalCursor;

    event NewProposal(uint proposalId, string name);
    event NewVote(address voter, uint proposalId, VoteOption[] vote);
    event NewMember(address newMember);
    event NewDateProposed(uint proposalId, Date dateProposed);

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

    struct Proposal {
        string name;
        address proposer;
        uint totalPositiveVoteNumber;
        uint totalNegativeVoteNumber;
        uint endingTime;
        VotingStatus status;
        mapping(uint => Date) datesProposed;
        mapping(uint => DateVotes) datesProposedVotes;
        uint datesCursor;
        mapping(address => bool) votingUsers;
    }

    constructor(string memory _name) {
        name = _name;
        proposalCursor = 0;
    }

    modifier isVotePossible(uint _proposalId){
        require(block.timestamp < placesProposed[_proposalId].endingTime, "Vote is no more possible");
        _;
    }

    modifier canUserVote(uint _proposalId) {
        // Check if the user has already voted in the proposal
        require(!placesProposed[_proposalId].votingUsers[msg.sender], "Already voted");
        _;
    }

    modifier isUserMember() {
        // Check if user is a member of the Activity
        require(ActivityMembers[msg.sender], "Not a Activity member");
        _;
    }

    modifier isProposalIdValid(uint _proposalId) {
        // Check if _proposalId points to an existing proposal
        require(_proposalId < proposalCursor, "ProposalId invalid");
        _;
    }

    /// @notice Manage who can enter the Activity
    /// @dev very simple for now needs to be implemented
    function joinActivity() external {
        ActivityMembers[msg.sender] = true;
        emit NewMember(msg.sender);
    }


    function propose(uint _duration, string memory _name, Date[] memory datesProposed) external isUserMember {
        Proposal storage newProposal = placesProposed[proposalCursor];
        newProposal.name = _name;
        newProposal.endingTime = block.timestamp + _duration;
        newProposal.proposer = msg.sender;
        newProposal.status = VotingStatus.PENDING;
        uint i;
        for (i = 0; i < datesProposed.length; i++){
            newProposal.datesProposed[i] = datesProposed[i];
        }
        newProposal.datesCursor = i + 1;
        proposalCursor += 1;
        emit NewProposal(proposalCursor - 1, _name);
    }

    function addDateToExistingProposal(uint proposalId, Date memory dateProposed) external isUserMember {
        Proposal storage proposal = placesProposed[proposalId];
        proposal.datesProposed[proposal.datesCursor] = dateProposed;
        proposal.datesCursor += 1;
        emit NewDateProposed(proposalId, dateProposed);
    }

    function vote(uint _proposalId, VoteOption[] memory userVotes) external isProposalIdValid(_proposalId) isVotePossible(_proposalId) isUserMember canUserVote(_proposalId) {
        Proposal storage proposal = placesProposed[_proposalId];

        require(proposal.status == VotingStatus.PENDING, "Vote is closed");
        for (uint i = 0; i < proposal.datesCursor; i++ ) {
            VoteOption userVote = userVotes[i];
            if (userVote == VoteOption.ACCEPT) {
                proposal.datesProposedVotes[i].positiveVoteNumber += 1;
            }
            else {
                proposal.datesProposedVotes[i].negativeVoteNumber += 1;
            }
            proposal.datesProposedVotes[i].totalVoteNumber += 1;
        }

        proposal.votingUsers[msg.sender] = true;
        
        emit NewVote(msg.sender, _proposalId, userVotes);
    }

    

}