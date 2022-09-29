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
  arbitrum: {
    chainlinkFeed: "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612",
    underlying: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
  },
  goerli: {
    chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    underlying: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
  },
  'goerli-fork': {
    chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    underlying: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
  }
}

module.exports = async function (deployer, network, accounts) {
  const isNetwork = networks => (networks.includes(network))
  const isLocal   = isNetwork(['test',   'development'])
  const isTestnet = isNetwork(['goerli', 'goerli-fork'])

  if (isLocal || isTestnet) {
    if (isLocal) {
      await deployer.deploy(MockMath)
      await deployer.deploy(MockPrice)
      await deployer.deploy(MockModel)
      await deployer.deploy(MockWETH, accounts)
    } else {
      await deployer.deploy(Price8Decimal, addrs[network].chainlinkFeed)
    }
    await deployer.deploy(LinearModel)

    const minDelay = (isLocal || isTestnet) ? 0 : (7 * 24 * 60 * 60)
    await deployer.deploy(Timelock, minDelay, [accounts[0]], ['0x0000000000000000000000000000000000000000'])

    //const hedge = await deployer.deploy(Token, "Hedged WETH", "EUSD", accounts[0])
    //const leverage = await deployer.deploy(Token, "Leveraged WETH", "LETH", accounts[0])
    //await deployer.deploy(Swap, MockPrice.address, MockModel.address, hedge.address, leverage.address, MockWETH.address)
    const hedge  = await deployProxy(Token, ["Hedged WETH",    "EUSD", accounts[0]], { deployer, kind: "uups" });
    const leverage = await deployProxy(Token, ["Leveraged WETH", "LETH", accounts[0]], { deployer, kind: "uups" });

    let priceAddr
    let modelAddr
    let underlyingAddr
    if (isLocal) {
      priceAddr = MockPrice.address
      modelAddr = MockModel.address
      underlyingAddr = MockWETH.address
    } else {
      priceAddr = Price8Decimal.address
      modelAddr = LinearModel.address
      underlyingAddr = addrs[network].underlying
    }
    const fee = isLocal ? '0' : '1000000000000000' // 0.1% to be safe, oracle updates every ~0.49% price change
    const params = await deployer.deploy(isLocal ? MockParameters : Parameters, fee, modelAddr, priceAddr, hedge.address, leverage.address, underlyingAddr)
    const swap = await deployProxy(Swap, [params.address], { deployer, kind: "uups" })

    await hedge.grantRole(await hedge.MINTER_ROLE.call(), swap.address)
    await hedge.grantRole(await hedge.DEFAULT_ADMIN_ROLE.call(), Timelock.address)
    await hedge.revokeRole(await hedge.DEFAULT_ADMIN_ROLE.call(), accounts[0])
    await leverage.grantRole(await leverage.MINTER_ROLE.call(), swap.address)
    await leverage.grantRole(await leverage.DEFAULT_ADMIN_ROLE.call(), Timelock.address)
    await leverage.revokeRole(await leverage.DEFAULT_ADMIN_ROLE.call(), accounts[0])

    if (!isLocal) {
      await swap.transferOwnership(Timelock.address)
    }

    fs.writeFileSync(`deployments-${network}.json`, JSON.stringify({
      hedge:  hedge.address,
      leverage: leverage.address,
      swap: swap.address,
      timelock: Timelock.address,
    }, undefined, 2))
  }
};
