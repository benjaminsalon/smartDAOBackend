const { expect } = require("chai");
const { ethers } = require("hardhat");


let activity;
let creator, user1, user2;

let stakeFee = 1000000;
let customToken; //USDC on ETH mainnet for now

describe.only("Activity Testing", function () {
  beforeEach(async () => {
    [creator, user1, user2] = await hre.ethers.getSigners();

    const CustomTokenFactory = await ethers.getContractFactory("CustomToken");
     customToken = await CustomTokenFactory.deploy("custom","cstm",creator.address,user1.address,user2.address);
    const ActivityHallFactory = await ethers.getContractFactory("ActivitiesHall");
    const activityHall = await ActivityHallFactory.deploy("Soccer Games");
    await activityHall.deployed();

    let deployTx = await activityHall.deployActivity("HelloActivity",  1000000, customToken.address, 60);
    await deployTx.wait();

    let activityAddress = await activityHall.activities(0);
    ActivityFactory = await ethers.getContractFactory("Activity");
    activity = await ActivityFactory.attach(activityAddress);

  });

  it("Should add a new user to the Activity", async function () {
    let isMember = await activity.ActivityMembers(creator.address)
    console.log(`ActivityMembers[creator] = ${isMember}`);

    isMember = await activity.ActivityMembers(user1.address)
    console.log(`ActivityMembers[user1] = ${isMember}`);

    console.log("Join activity for user1");

    let addTx = await activity.connect(user1).joinActivity();
    let addRc = await addTx.wait();

    addEv = addRc.events.find(
      (evInfo) => evInfo.event == "NewMember"
    )

    console.log(addEv.args);
    isMember = await activity.ActivityMembers(user1.address)
    console.log(`ActivityMembers[user1] = ${isMember}`);
  });

  it("Should add new location proposals", async function () {
    let addTx = await activity.connect(user1).joinActivity();
    let addRc = await addTx.wait();
    addTx = await activity.connect(user2).joinActivity();
    addRc = await addTx.wait();

    tx = await activity.connect(user1).proposeLocation("Stadium 1", [[100],[200],[300]]);
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "NewLocation"
    )
  
    console.log(ev.args);

    tx = await activity.connect(user2).proposeLocation("Stadium 1", [[100],[200],[300]]);
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "NewLocation"
    )
  
    console.log(ev.args);
  });


  it.only("Should allow voting", async function () {
    let addTx = await activity.connect(user1).joinActivity();
    let addRc = await addTx.wait();
    addTx = await activity.connect(user2).joinActivity();
    addRc = await addTx.wait();

    tx = await activity.connect(user1).proposeLocation("Stadium 1", [[100],[200],[300]]);
    rc = await tx.wait();

    tx = await activity.connect(user2).proposeLocation("Stadium 2", [[100],[200]]);
    rc = await tx.wait();

    //Need to approve the activity to take the tokens

    tx = await customToken.connect(user2).approve(activity.address, 10000000);
    rc = await tx.wait();

    tx = await activity.connect(user2).vote(0, [0,1,0]);
    rc = await tx.wait();
  });
});
