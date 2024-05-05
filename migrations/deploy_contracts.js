const ArtToken = artifacts.require("ArtToken");
const ArtAuction = artifacts.require("ArtAuction");
const AuctionAccessControl = artifacts.require("AuctionAccessControl");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(ArtToken);
  const artTokenInstance = await ArtToken.deployed();

  await deployer.deploy(AuctionAccessControl);
  const auctionAccessControlInstance = await AuctionAccessControl.deployed();

  await deployer.deploy(ArtAuction, artTokenInstance.address, auctionAccessControlInstance.address);
  const artAuctionInstance = await ArtAuction.deployed();
  
  if (network !== 'live') {
    console.log('Setting up demo environment...');
    await artAuctionInstance.setupDemoEnvironment({ from: accounts[0] });
    console.log('Demo environment setup complete.');
  }
};