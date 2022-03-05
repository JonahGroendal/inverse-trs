const fs = require('fs')
const Migrations = artifacts.require("Migrations");
const Token = artifacts.require("Token");
const Swap = artifacts.require("Swap");
const MockRates = artifacts.require("MockRates");
const MockWETH = artifacts.require("MockWETH");
const MathUtils = artifacts.require("MathUtils");
const MockMath = artifacts.require("MockMath");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(MathUtils)
  await deployer.link(MathUtils, MockMath);
  await deployer.link(MathUtils, MockRates);
  await deployer.deploy(MockMath)
  await deployer.deploy(MockRates)
  await deployer.deploy(MockWETH, accounts)

  const tokenH = await deployer.deploy(Token, "Hedged WETH", "EUSD", accounts[0])
  const tokenL = await deployer.deploy(Token, "Leveraged WETH", "LETH", accounts[0])
  await deployer.deploy(Swap, MockRates.address, tokenH.address, tokenL.address, MockWETH.address)

  await tokenH.grantRole(await tokenH.MINTER_ROLE.call(), Swap.address)
  await tokenL.grantRole(await tokenL.MINTER_ROLE.call(), Swap.address)

  fs.writeFileSync('contractAddrs.json', JSON.stringify({
    EUSD: tokenH.address,
    LETH: tokenL.address
  }, undefined, 2))

};
