const ArtTokenContract = artifacts.require("ArtToken");
const ArtAuctionContract = artifacts.require("ArtAuction");
const AuctionAccessControlContract = artifacts.require("AuctionAccessControl");

module.exports = async function (deployer, network, accounts) {
  try {
    const artTokenInstance = await deployArtToken(deployer);
    const accessControlInstance = await deployAccessControl(deployer);
    await deployArtAuction(deployer, artTokenInstance, accessControlInstance);

    if (network !== 'live') {
      await setupDemoEnvironment(artTokenInstance, accessControlInstance, accounts);
    }
  } catch (error) {
    console.error("An error occurred during the deployment process:", error);
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

async function deployArtAuction(deployer, artTokenInstance, accessControlInstance) {
  await deployer.deploy(ArtAuctionContract, artTokenInstance.address, accessControlInstance.address);
  return await ArtAuctionContract.deployed();
}

async function setupDemoEnvironment(artTokenInstance, accessControlInstance, accounts) {
  console.log('Setting up demo environment...');
  const artAuctionInstance = await ArtAuctionContract.deployed();
  await artAuctionInstance.setupDemoEnvironment({ from: accounts[0] });
  console.log('Demo environment setup complete.');
}