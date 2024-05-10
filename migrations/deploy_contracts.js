const ArtTokenContract = artifacts.require("ArtToken");
const ArtAuctionContract = artifacts.require("ArtAuction");
const AuctionAccessControlContract = artifacts.require("AuctionAccessControl");

module.exports = async function (deployer, network, accounts) {
  try {
    const artTokenDeployed = await deployArtToken(deployer);
    const accessControlDeployed = await deployAccessControl(deployer);
    await deployArtAuction(deployer, artTokenDeployed, accessControlDeployed);

    if (network !== 'live') {
      await initializeDemoEnvironment(artTokenDeployed, accessControlDeployed, accounts);
    }
  } catch (error) {
    console.error("Deployment error:", error);
  }
};

async function deployArtToken(deployer) {
  await deployer.deploy(ArtTokenContract);
  return await ArtTokenContract.deployed();
}

async function deployAccessControl(deployer) {
  await deployer.deploy(AuctionAccessControlContract);
  return await AuctionAccessControlContract.deployed();
}

async function deployArtAuction(deployer, tokenInstance, accessControlInstance) {
  await deployer.deploy(ArtAuctionContract, tokenInstance.address, accessControlInstance.address);
  return await ArtAuctionContract.deployed();
}

async function initializeDemoEnvironment(tokenInstance, accessControlInstance, demoAccounts) {
  console.log('Initializing demo environment...');
  const auctionInstance = await ArtAuctionContract.deployed();
  await auctionInstance.initializeDemo({ from: demoAccounts[0] });
  console.log('Demo environment initialization complete.');
}