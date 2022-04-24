# ActivityDAO
 ## Short Description 
  We try to implement a costless DAO to facilitate the creation and the  manipulation of sub-communities around activities.
  
 ## Long Description
 We are planning to improve the DAO's by implementing manipulation features like:
 the possibility for someone to join a DAO community around an activity for free and quickly
 the possibility for someone to create a DAO community around an activity
 as a member of a DAO community, you’ll be able to vote for events oncoming and also propose new events at a new place or new date
 The token used is an ERC20 allowing users to participate in the DAO by staking an amount of tokens. If someone does not participate in the event he had stacked for, he
 loses the amount of token stacked.This amount is going to be shared between people really participating in the event.  By participating in an event, the user is able to
 claim for his stake and a part of the non participating people. We also used IPFS in order to store the avatar of the user as a NFT.

## How It's Made
Firstly, in order to participate in the DAO, the user needs to connect himself by connecting his Wallet. So we used Metamask there. The user is also able to upload a file representing his avatar. The avatar file is going to be stored on-chain on IPFS as a NFT for the user. 
Secondly, we use SKALE network to provide a DAO for free for everyone : no gas fees, quick to deploy and to interact with the contract. It also allows us to build in a near future our own league with the RNG providing a full random matchmaking between teams in a sport competition for example. 


## Frontend Code
You can access the backend code in the following link : https://github.com/Gerkep/SmartDAO
