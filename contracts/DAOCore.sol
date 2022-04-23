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

    Proposal[] public proposals;

    mapping(address => bool) public DAOMembers;

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
        uint positiveVoteNumber;
        uint negativeVoteNumber;
        uint endingTime;
        VotingStatus status;
        mapping(address => bool) userVotes;
    }

    constructor(string memory _name) {
        name = _name;
    }

    modifier isVotePossible(uint _proposalId){
        require(block.timestamp < proposals[_proposalId].endingTime, "Vote is no more possible");
        _;
    }

    modifier canUserVote(uint _proposalId) {
        // Check if user is a member of the DAO
        require(DAOMembers[msg.sender], "Not a DAO member");
        // Check if the user has already voted in the proposal
        require(!proposals[_proposalId].userVotes[msg.sender], "Already voted");
        _;
    }

    function proposeVote(uint _endingTime, string _name) external {
        Proposal memory newProposal = Proposal({name : _name, endingTime: _endingTime});
        proposals.push(newProposal);
    }

    // function addProposalToVote(uint _voteId, Proposal memory _proposal) external isVotePossible(_voteId) {
    //     proposals[_voteId].proposals.push(_proposal);
    // }
    

    function vote(uint _proposalId, VoteOption myVote) external isVotePossible(_proposalId) canUserVote(_proposalId) {

    }

}