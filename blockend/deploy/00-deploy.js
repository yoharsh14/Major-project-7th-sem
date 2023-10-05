const { network } = require("hardhat");
const developmentChains = ["hardhat", "localhost"];
const { verify } = require("../scripts/verify.js");
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const nftMarketplace = await deploy("NFTMarketplace", {
    from: deployer,
    log: true,
    args: [],
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  if (!developmentChains.includes(network.name)) {
    await verify(nftMarketplace.address, []);
  }
};
module.exports.tags = [];
