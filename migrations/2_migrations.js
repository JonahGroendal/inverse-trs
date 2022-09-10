const fs = require('fs')
const Migrations = artifacts.require("Migrations");
const Token = artifacts.require("Token");
const Swap = artifacts.require("Swap");
//const Rates = artifacts.require("Rates");
const MockModel = artifacts.require("MockModel")
const LinearModel = artifacts.require("LinearModel")
const MockPriceFeed = artifacts.require("MockPriceFeed");
const MockWETH = artifacts.require("MockWETH");
const MathUtils = artifacts.require("MathUtils");
const MockMath = artifacts.require("MockMath");

module.exports = async function (deployer, network, accounts) {
  if (network === 'test' || network === 'development') {
    //await deployer.deploy(MathUtils)
    await deployer.deploy(MockMath)
    await deployer.deploy(MockPriceFeed)
    await deployer.deploy(MockModel)
    await deployer.deploy(LinearModel)
    //await deployer.deploy(Rates, MockPriceFeed.address, MockModel.address)
    await deployer.deploy(MockWETH, accounts)

    const tokenH = await deployer.deploy(Token, "Hedged WETH", "EUSD", accounts[0])
    const tokenL = await deployer.deploy(Token, "Leveraged WETH", "LETH", accounts[0])
    await deployer.deploy(Swap, MockPriceFeed.address, MockModel.address, tokenH.address, tokenL.address, MockWETH.address)

    await tokenH.grantRole(await tokenH.MINTER_ROLE.call(), Swap.address)
    await tokenL.grantRole(await tokenL.MINTER_ROLE.call(), Swap.address)

    fs.writeFileSync('contractAddrsTest.json', JSON.stringify({
      EUSD: tokenH.address,
      LETH: tokenL.address
    }, undefined, 2))
  }

};
