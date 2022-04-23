const { expect } = require("chai");
const { Contract } = require("ethers");
const { ethers } = require("hardhat");


let activity;
let creator, user1, user2, user3, user4;

let stakeFee = 1000000;
let customToken; //USDC on ETH mainnet for now

describe.only("Activity Testing", function () {
  beforeEach(async () => {
    [creator, user1, user2,user3, user4] = await hre.ethers.getSigners();

    const CustomTokenFactory = await ethers.getContractFactory("CustomToken");
     customToken = await CustomTokenFactory.deploy("custom","cstm",creator.address,user1.address,user2.address,user3.address, user4.address);
    const ActivityHallFactory = await ethers.getContractFactory("ActivitiesHall");
    const activityHall = await ActivityHallFactory.deploy("Soccer Games");
    await activityHall.deployed();

    let deployTx = await activityHall.deployActivity("HelloActivity",  2, 1000000, customToken.address, 20);
    await deployTx.wait();

    let activityAddress = await activityHall.activities(0);
    ActivityFactory = await ethers.getContractFactory("Activity");
    activity = await ActivityFactory.attach(activityAddress);

  });

  it("Should add a new user to the Activity", async function () {
    let isMember = await activity.activityMembers(creator.address)
    console.log(`activityMembers[creator] = ${isMember}`);

    isMember = await activity.activityMembers(user1.address)
    console.log(`activityMembers[user1] = ${isMember}`);

    console.log("Join activity for user1");

    let addTx = await activity.connect(user1).joinActivity();
    let addRc = await addTx.wait();

    addEv = addRc.events.find(
      (evInfo) => evInfo.event == "NewMember"
    )

    console.log(addEv.args);
    isMember = await activity.activityMembers(user1.address)
    console.log(`activityMembers[user1] = ${isMember}`);
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


  it("Should allow voting", async function () {
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

    ev = rc.events.find(
        (evInfo) => evInfo.event == "NewVote"
    )
  
    console.log(ev.args);

  });

  it("Should allow the vote to finish and reach consensus", async function () {
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

    tx = await customToken.connect(user3).approve(activity.address, 10000000);
    rc = await tx.wait();

    tx = await activity.connect(user3).vote(0, [1,1,0]);
    rc = await tx.wait();

    await expect(activity.getResultVoting()).to.revertedWith("Vote is not closed");

    await sleep(15000);


    tx = await activity.getResultVoting();
    rc = await tx.wait();

    consensusReached = await activity.consensusReached();
    expect(consensusReached).to.equal(true);

  });

  it("Should allow the vote to finish and NOT reach consensus", async function () {
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

    // We don't have enough user voting
    // tx = await activity.connect(user2).vote(0, [0,1,0]);
    // rc = await tx.wait();

    await expect(activity.getResultVoting()).to.revertedWith("Vote is not closed");

    await sleep(15000);


    tx = await activity.getResultVoting();
    rc = await tx.wait();

    consensusReached = await activity.consensusReached();
    expect(consensusReached).to.equal(false);

  });

  it("Should allow the vote to finish and reach consensus and allow user to claim", async function () {
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

    tx = await customToken.connect(user1).approve(activity.address, 10000000);
    rc = await tx.wait();

    balanceUser2BeforeVote = await customToken.balanceOf(user2.address);
    balanceUser1BeforeVote = await customToken.balanceOf(user1.address);

    console.log(`Balance user1 before voting : ${balanceUser1BeforeVote}`);
    console.log(`Balance user2 before voting : ${balanceUser2BeforeVote}`);

    tx = await activity.connect(user2).vote(0, [0,1,0]);
    rc = await tx.wait();

    tx = await activity.connect(user1).vote(1, [0,1]);
    rc = await tx.wait();

    await expect(activity.getResultVoting()).to.revertedWith("Vote is not closed");

    await sleep(15000);


    tx = await activity.getResultVoting();
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "ResultingVote"
    )
  
    console.log(ev.args);

    consensusReached = await activity.consensusReached();
    // expect(consensusReached).to.equal(true);

    balanceUser2Before = await customToken.balanceOf(user2.address);
    balanceUser1Before = await customToken.balanceOf(user1.address);

    console.log(`Balance user1 before getting stake back : ${balanceUser1Before}`);
    console.log(`Balance user2 before getting stake back : ${balanceUser2Before}`);

    tx = await activity.connect(user2).claimUnusedStaking();
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "AmountSentBackToUser"
    )
  
    console.log(ev.args);

    tx = await activity.connect(user1).claimUnusedStaking();
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "AmountSentBackToUser"
    )
  
    console.log(ev.args);

    balanceUser2After = await customToken.balanceOf(user2.address);
    balanceUser1After = await customToken.balanceOf(user1.address);

    console.log(`Balance user1 after getting stake back : ${balanceUser1After}`);
    console.log(`Balance user2 after getting stake back : ${balanceUser2After}`);

    // user cannot claim twice
    await expect(activity.connect(user1).claimUnusedStaking()).to.revertedWith("Member has already claimed back");
  });

  it("Should test the check-in process (partly...)", async function () {
    let addTx = await activity.connect(user1).joinActivity();
    let addRc = await addTx.wait();
    addTx = await activity.connect(user2).joinActivity();
    addRc = await addTx.wait();
    addTx = await activity.connect(user3).joinActivity();
    addRc = await addTx.wait();
    addTx = await activity.connect(user4).joinActivity();
    addRc = await addTx.wait();

    tx = await activity.connect(user1).proposeLocation("Stadium 1", [[100],[200],[300]]);
    rc = await tx.wait();

    tx = await activity.connect(user2).proposeLocation("Stadium 2", [[100],[200]]);
    rc = await tx.wait();

    //Need to approve the activity to take the tokens

    tx = await customToken.connect(user2).approve(activity.address, 10000000);
    rc = await tx.wait();

    tx = await customToken.connect(user1).approve(activity.address, 10000000);
    rc = await tx.wait();

    tx = await customToken.connect(user3).approve(activity.address, 10000000);
    rc = await tx.wait();

    tx = await customToken.connect(user4).approve(activity.address, 10000000);
    rc = await tx.wait();

    
    balanceUser1BeforeVote = await customToken.balanceOf(user1.address);
    balanceUser2BeforeVote = await customToken.balanceOf(user2.address);
    balanceUser3BeforeVote = await customToken.balanceOf(user3.address);
    balanceUser4BeforeVote = await customToken.balanceOf(user4.address);

    console.log(`Balance user1 before voting : ${balanceUser1BeforeVote}`);
    console.log(`Balance user2 before voting : ${balanceUser2BeforeVote}`);
    console.log(`Balance user3 before voting : ${balanceUser3BeforeVote}`);
    console.log(`Balance user4 before voting : ${balanceUser4BeforeVote}`);

    tx = await activity.connect(user1).vote(1, [0,1]);
    rc = await tx.wait();

    tx = await activity.connect(user2).vote(0, [0,1,0]);
    rc = await tx.wait();

    tx = await activity.connect(user3).vote(0, [0,1,1]);
    rc = await tx.wait();

    tx = await activity.connect(user4).vote(0, [1,1,1]);
    rc = await tx.wait();

    tx = await activity.connect(user4).vote(1, [1,1]);
    rc = await tx.wait();
    
    await expect(activity.getResultVoting()).to.revertedWith("Vote is not closed");

    await sleep(15000);

    tx = await activity.getResultVoting();
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "ResultingVote"
    )
  
    console.log(ev.args);

    consensusReached = await activity.consensusReached();
    expect(consensusReached).to.equal(true);

    balanceUser1Before = await customToken.balanceOf(user1.address);
    balanceUser2Before = await customToken.balanceOf(user2.address);
    balanceUser3Before = await customToken.balanceOf(user3.address);
    balanceUser4Before = await customToken.balanceOf(user4.address);
    

    console.log(`Balance user1 before getting stake back : ${balanceUser1Before}`);
    console.log(`Balance user2 before getting stake back : ${balanceUser2Before}`);
    console.log(`Balance user3 before getting stake back : ${balanceUser3Before}`);
    console.log(`Balance user4 before getting stake back : ${balanceUser4Before}`);

    tx = await activity.connect(user1).claimUnusedStaking();
    rc = await tx.wait();

    tx = await activity.connect(user2).claimUnusedStaking();
    rc = await tx.wait();

    tx = await activity.connect(user3).claimUnusedStaking();
    rc = await tx.wait();

    tx = await activity.connect(user4).claimUnusedStaking();
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "AmountSentBackToUser"
    )
  
    console.log(ev.args);
    
    balanceUser1After = await customToken.balanceOf(user1.address);
    balanceUser2After = await customToken.balanceOf(user2.address);
    balanceUser3After = await customToken.balanceOf(user3.address);
    balanceUser4After = await customToken.balanceOf(user4.address);

    console.log(`Balance user1 after getting stake back : ${balanceUser1After}`);
    console.log(`Balance user2 after getting stake back : ${balanceUser2After}`);
    console.log(`Balance user3 after getting stake back : ${balanceUser3After}`);
    console.log(`Balance user4 after getting stake back : ${balanceUser4After}`);
    // user cannot claim twice
    await expect(activity.connect(user1).claimUnusedStaking()).to.revertedWith("Member has already claimed back");

    // Check-in part tadadaaaam

    //Check that we have user2 and user3 in membersParticipatingArray
    lengthParticipantsArray = await activity.lengthParticipantsArray();
    console.log("Registered participants")
    for (i = 0; i < lengthParticipantsArray; i++) {
        member = await activity.participantsArray(i);
        console.log(member)
    }
    console.log("Signers:")
    console.log(`Creator: ${creator.address}`);
    console.log(`User1: ${user1.address}`);
    console.log(`User2: ${user2.address}`);
    console.log(`User3: ${user3.address}`);
    console.log(`User4: ${user4.address}`);
    
    presenceArrayUser = ["0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC","0x90F79bf6EB2c4f870365E785982E1f101E93b906","0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"];
    presenceArrayUser2 = ["0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"];
    presenceArrayUser3 = ["0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", "0x90F79bf6EB2c4f870365E785982E1f101E93b906"];
    presenceArrayUser4 = ["0x90F79bf6EB2c4f870365E785982E1f101E93b906", "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"];

    // await expect( activity.connect(user1).statePresence(presenceArrayUser)).to.revertedWith("User is not participating");

    await expect( activity.connect(user2).claimStake()).to.revertedWith("Not enough presence votes");

    tx = await activity.connect(user2).statePresence(presenceArrayUser2);
    rc = await tx.wait();

    await expect( activity.connect(user2).claimStake()).to.revertedWith("Not enough presence votes");

    tx = await activity.connect(user3).statePresence(presenceArrayUser3);
    rc = await tx.wait();

    tx = await activity.connect(user2).claimStake();
    rc = await tx.wait();

    ev = rc.events.find(
        (evInfo) => evInfo.event == "StakeClaimed"
    )
  
    console.log(`StakeClaimed user2: ${ev.args}`);

    await expect( activity.connect(user3).claimStake()).to.revertedWith("Not enough presence votes");

    tx = await activity.connect(user4).statePresence(presenceArrayUser4);
    rc = await tx.wait();

    console.log("before user3 claimStake")
    tx = await activity.connect(user3).claimStake();
    rc = await tx.wait();

    console.log("before user4 claimStake")
    tx = await activity.connect(user4).claimStake();
    rc = await tx.wait();

  });



});


function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }