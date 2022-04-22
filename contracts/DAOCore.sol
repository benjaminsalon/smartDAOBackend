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

    constructor(string memory _name) {
        name = _name;
    }
}