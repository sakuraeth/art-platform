const ArtTokenContract = artifacts.require("ArtToken");
const ArtAuctionContract = artifacts.require("ArtAuction");
const AuctionAccessControlContract = artifacts.require("AuctionAccessControl");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(ArtTokenContract);
  const artTokenInstance = await ArtTokenContract.deployed();

  await deployer.deploy(AuctionAccessControlContract);
  const accessControlInstance = await AuctionAccessControlContract.deployed();

  await deployer.deploy(ArtAuctionContract, artTokenInstance.address, accessControlInstance.address);
  const artAuctionInstance = await ArtAuctionContract.deployed();
  
  if (network !== 'live') {
    console.log('Setting up demo environment...');
    await artAuctionInstance.setupDemoEnvironment({ from: accounts[0] });
    console.log('Demo environment setup complete.');
  }
};