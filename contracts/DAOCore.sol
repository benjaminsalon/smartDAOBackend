// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DAOFactory {

    address[] public deployedDAO;
    event DAODeployed(address newDAOAddress, string name);

    constructor() {

    }

    function deployDAO(string memory _name) external {
        address newDAO = address(new DAO(_name));
        deployedDAO.push(newDAO);
        emit DAODeployed(newDAO,_name);
    }


}

contract DAO {

    string public name;

    mapping(address => bool) public DAOMembers;
    mapping(uint => Proposal) public proposals;

    uint public proposalCursor;

    event NewProposal(uint proposalId, string name);
    event NewVote(address voter, uint proposalId, VoteOption vote);
    event NewMember(address newMember);

    enum VotingStatus {
        PENDING,
        ACCEPTED,
        REJECTED
    }

    enum VoteOption {
        ACCEPT,
        REJECT
    }

    struct Proposal {
        string name;
        address proposer;
        uint positiveVoteNumber;
        uint negativeVoteNumber;
        uint endingTime;
        VotingStatus status;
        mapping(address => bool) userVotes;
    }

    constructor(string memory _name) {
        name = _name;
        proposalCursor = 0;
    }

    modifier isVotePossible(uint _proposalId){
        require(block.timestamp < proposals[_proposalId].endingTime, "Vote is no more possible");
        _;
    }

    modifier canUserVote(uint _proposalId) {
        // Check if the user has already voted in the proposal
        require(!proposals[_proposalId].userVotes[msg.sender], "Already voted");
        _;
    }

    modifier isUserMember() {
         // Check if user is a member of the DAO
        require(DAOMembers[msg.sender], "Not a DAO member");
        _;
    }

    /// @notice Manage who can enter the DAO
    /// @dev very simple for now needs to be implemented
    function joinDAO() external {
        DAOMembers[msg.sender] = true;
        emit NewMember(msg.sender);
    }


    function propose(uint _endingTime, string memory _name) external isUserMember {
        Proposal storage newProposal = proposals[proposalCursor];
        newProposal.name = _name;
        newProposal.endingTime = _endingTime;
        newProposal.proposer = msg.sender;
        newProposal.status = VotingStatus.PENDING;
        proposalCursor += 1;
        emit NewProposal(proposalCursor - 1, _name);
    }

    function vote(uint _proposalId, VoteOption userVote) external isVotePossible(_proposalId) isUserMember canUserVote(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        require(proposal.status == VotingStatus.PENDING, "Vote is closed");

        if (userVote == VoteOption.ACCEPT) {
            proposal.positiveVoteNumber += 1;
        }
        else {
            proposal.negativeVoteNumber += 1;
        }

        emit NewVote(msg.sender, _proposalId, userVote);
    }

    

}