const { expect } = require("chai");
const { ethers } = require("hardhat");


let daoContract;

describe("DAO", function () {
  beforeEach(async () => {
    const DAOFactory = await ethers.getContractFactory("DAOFactory");
    const daoFactory = await DAOFactory.deploy();
    await daoFactory.deployed();

    let deployTx = await daoFactory.deployDAO("HelloDAO");
    await deployTx.wait();

    let dao = await daoFactory.deployedDAO(0);
    DAO = await ethers.getContractFactory("DAO");
    daoContract = await DAO.attach(dao);

  });

  it("Should add a new user to the DAO", async function () {
    let addTx = await daoContract.joinDAO();
    let addRc = await addTx.wait();

    addEv = addRc.events.find(
      (evInfo) => evInfo.event == "NewMember"
    )

    console.log(addEv.args);
  });
});
