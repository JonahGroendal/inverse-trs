const fs = require('fs')
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const Migrations = artifacts.require("Migrations");
const Token = artifacts.require("Token");
const Swap = artifacts.require("Swap");
const MockModel = artifacts.require("MockModel")
const LinearModel = artifacts.require("LinearModel")
const MockPriceFeed = artifacts.require("MockPriceFeed");
const MockWETH = artifacts.require("MockWETH");
const MockMath = artifacts.require("MockMath");

const addrs = {
  goerli: {
    chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    weth: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
  }
}

module.exports = async function (deployer, network, accounts) {
  if (network === 'test' || network === 'development') {
    await deployer.deploy(MockMath)
    await deployer.deploy(MockPriceFeed)
    await deployer.deploy(MockModel)
    await deployer.deploy(LinearModel)
    await deployer.deploy(MockWETH, accounts)

    //const tokenH = await deployer.deploy(Token, "Hedged WETH", "EUSD", accounts[0])
    //const tokenL = await deployer.deploy(Token, "Leveraged WETH", "LETH", accounts[0])
    //await deployer.deploy(Swap, MockPriceFeed.address, MockModel.address, tokenH.address, tokenL.address, MockWETH.address)

    const tokenH = await deployProxy(Token, ["Hedged WETH", "EUSD",    accounts[0]], { deployer, kind: "uups" });
    const tokenL = await deployProxy(Token, ["Leveraged WETH", "LETH", accounts[0]], { deployer, kind: "uups" });
    const swap   = await deployProxy(Swap, [MockPriceFeed.address, MockModel.address, tokenH.address, tokenL.address, MockWETH.address], { deployer, kind: "uups" });
    //console.log('tokenL:', tokenL.address)
    //await deployer.deploy(Swap, MockPriceFeed.address, MockModel.address, tokenH.address, tokenL.address, MockWETH.address)

    await tokenH.grantRole(await tokenH.MINTER_ROLE.call(), swap.address)
    await tokenL.grantRole(await tokenL.MINTER_ROLE.call(), swap.address)

    fs.writeFileSync('contractAddrsTest.json', JSON.stringify({
      EUSD: tokenH.address,
      LETH: tokenL.address,
      swap: swap.address
    }, undefined, 2))
  } else if (network == 'goerli') {
    await deployer.deploy(LinearModel)
    const tokenH = await deployProxy(Token, ["Hedged WETH", "EUSD",    accounts[0]], { deployer, kind: "uups" });
    const tokenL = await deployProxy(Token, ["Leveraged WETH", "LETH", accounts[0]], { deployer, kind: "uups" });
    const swap   = await deployProxy(Swap, [addrs.goerli.chainlinkFeed, LinearModel.address, tokenH.address, tokenL.address, addrs.goerli.weth], { deployer, kind: "uups" });

    fs.writeFileSync('contractAddrsGoerli.json', JSON.stringify({
      EUSD: tokenH.address,
      LETH: tokenL.address,
      swap: swap.address
    }, undefined, 2))
  }

};
