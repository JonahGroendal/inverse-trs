const fs = require('fs')
const { deployProxy } = require('@openzeppelin/truffle-upgrades')
const Migrations = artifacts.require("Migrations")
const Token = artifacts.require("Token")
const Swap = artifacts.require("Swap")
const Parameters = artifacts.require("Parameters")
const MockParameters = artifacts.require("MockParameters")
const LinearModel = artifacts.require("LinearModel")
const Price8Decimal = artifacts.require("Price8Decimal")
const Timelock = artifacts.require("Timelock")
const MockModel = artifacts.require("MockModel")
const MockPrice = artifacts.require("MockPrice")
const MockWETH = artifacts.require("MockWETH")
const MockMath = artifacts.require("MockMath")

const addrs = {
  goerli: {
    chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    weth: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
  },
  'goerli-fork': {
    chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    weth: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
  }
}

module.exports = async function (deployer, network, accounts) {
  const isNetwork = networks => (networks.includes(network))
  const isTest = isNetwork(['test', 'development'])

  if (isNetwork(['test', 'development', 'goerli', 'goerli-fork'])) {
    if (isTest) {
      await deployer.deploy(MockMath)
      await deployer.deploy(MockPrice)
      await deployer.deploy(MockModel)
      await deployer.deploy(MockWETH, accounts)
    } else {
      await deployer.deploy(Price8Decimal, addrs[network].chainlinkFeed)
    }
    await deployer.deploy(LinearModel)

    await deployer.deploy(Timelock, 0, [accounts[0]], ['0x0000000000000000000000000000000000000000'])

    //const fixedLeg = await deployer.deploy(Token, "Hedged WETH", "EUSD", accounts[0])
    //const floatLeg = await deployer.deploy(Token, "Leveraged WETH", "LETH", accounts[0])
    //await deployer.deploy(Swap, MockPrice.address, MockModel.address, fixedLeg.address, floatLeg.address, MockWETH.address)
    const fixedLeg = await deployProxy(Token, ["Hedged WETH", "EUSD",    accounts[0]], { deployer, kind: "uups" });
    const floatLeg = await deployProxy(Token, ["Leveraged WETH", "LETH", accounts[0]], { deployer, kind: "uups" });

    let priceAddr
    let modelAddr
    let wethAddr
    if (isTest) {
      priceAddr = MockPrice.address
      modelAddr = MockModel.address
      wethAddr = MockWETH.address
    } else {
      priceAddr = Price8Decimal.address
      modelAddr = LinearModel.address
      wethAddr = addrs[network].weth
    }
    const params = await deployer.deploy(isTest ? MockParameters : Parameters, '0', modelAddr, priceAddr, fixedLeg.address, floatLeg.address, wethAddr)
    const swap = await deployProxy(Swap, [params.address], { deployer, kind: "uups" })

    await fixedLeg.grantRole(await fixedLeg.MINTER_ROLE.call(), swap.address)
    await floatLeg.grantRole(await floatLeg.MINTER_ROLE.call(), swap.address)
    await fixedLeg.grantRole(await fixedLeg.DEFAULT_ADMIN_ROLE.call(), Timelock.address)
    await floatLeg.grantRole(await floatLeg.DEFAULT_ADMIN_ROLE.call(), Timelock.address)
    await floatLeg.revokeRole(await floatLeg.DEFAULT_ADMIN_ROLE.call(), accounts[0])
    await fixedLeg.revokeRole(await fixedLeg.DEFAULT_ADMIN_ROLE.call(), accounts[0])

    if (!isTest) {
      await swap.transferOwnership(Timelock.address)
    }

    fs.writeFileSync(`contractAddrs-${network}.json`, JSON.stringify({
      fixedLeg: fixedLeg.address,
      floatLeg: floatLeg.address,
      swap: swap.address,
      timelock: Timelock.address,
    }, undefined, 2))
  }
};
