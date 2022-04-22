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

    Vote[] public votes;

    struct Proposal {
        string name;
        uint voteNumber;
    }

    struct Vote {
        Proposal[] proposals;
        uint endingTime;
    }

    constructor(string memory _name) {
        name = _name;
    }

    modifier isVotePossible(uint _voteId){
        require(block.timestamp < votes[_voteId].endingTime, "Vote is no more possible");
        _;
    }

    function proposeVote(uint _endingTime, Proposal[] memory _startingProposals) external {
        Vote memory newVote = Vote({endingTime: _endingTime, proposals:_startingProposals});
        votes.push(newVote);
    }

    function addProposalToVote(uint _voteId, Proposal memory _proposal) external isVotePossible(_voteId) {
        votes[_voteId].proposals.push(_proposal);
    }
    


}