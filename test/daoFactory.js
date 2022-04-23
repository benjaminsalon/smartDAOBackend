const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DAOFactory", function () {
  it("Should create a new DAO", async function () {
    const DAOFactory = await ethers.getContractFactory("DAOFactory");
    const daoFactory = await DAOFactory.deploy();
    await daoFactory.deployed();

    let deployTx = await daoFactory.deployDAO("HelloDAO");
    let deployTxReceipt = await deployTx.wait();

    let dao1 = await daoFactory.deployedDAO(0);

    console.log(`Address of deployed dao: ${dao1}`);

    deployEv = deployTxReceipt.events.find(
      (evInfo) => evInfo.event == "DAODeployed"
    )

    console.log(deployEv.args);
    expect(dao1).not.equal(0);

    //Deploy second DAO
    console.log("Deploy second DAO");
    deployTx = await daoFactory.deployDAO("HelloDAO number 2");
    deployTxReceipt = await deployTx.wait();

    dao2 = await daoFactory.deployedDAO(1);

    console.log(`Address of deployed dao: ${dao2}`);

    deployEv = deployTxReceipt.events.find(
      (evInfo) => evInfo.event == "DAODeployed"
    )

    console.log(deployEv.args);
    expect(dao2).not.equal(0);
  });
});
