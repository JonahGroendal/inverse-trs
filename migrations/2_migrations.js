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

const consts = {
  hedgeName: "USD Synth (ETH-backed)",
  hedgeSymbol: "USDᵉᵗʰ",
  leverageName: "ETHUSD Long",
  leverageSymbol: "ETHUSD",
  swapName: "ETH/USD Swap",
  addrs: {
    dashboard: {
      name: "arbitrum",
      chainlinkFeed: "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612",
      underlying: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
      timelock: undefined // deploy a new timelock
    },
    goerli: {
      name: "goerli",
      chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
      underlying: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
    },
    'goerli-fork': {
      name: "goerli-fork",
      chainlinkFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
      underlying: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
    },
    test: {
      name: "test",
    }
  }
}

module.exports = async function (deployer, network, accounts) {
  const isNetwork = networks => (networks.includes(network))
  const isLocal   = isNetwork(['test',   'development'])
  const isTestnet = isNetwork(['goerli', 'goerli-fork'])
  const isMainnet = isNetwork(['dashboard'])

  if (isLocal || isTestnet || isMainnet) {
    if (isLocal) {
      await deployer.deploy(MockMath)
      await deployer.deploy(MockPrice)
      await deployer.deploy(MockModel)
      await deployer.deploy(MockWETH, accounts)
    } else {
      await deployer.deploy(Price8Decimal, consts.addrs[network].chainlinkFeed)
    }
    await deployer.deploy(LinearModel)

    let timelockAddr = consts.addrs[network].timelock
    if (!timelockAddr) {
      const minDelay = (isLocal || isTestnet) ? 0 : (7 * 24 * 60 * 60)
      await deployer.deploy(Timelock, minDelay, [accounts[0]], ['0x0000000000000000000000000000000000000000'])
      timelockAddr = Timelock.address
    }

    const hedge    = await deployProxy(Token, [consts.hedgeName,    consts.hedgeSymbol,    accounts[0]], { deployer, kind: "uups" });
    const leverage = await deployProxy(Token, [consts.leverageName, consts.leverageSymbol, accounts[0]], { deployer, kind: "uups" });

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
      underlyingAddr = consts.addrs[network].underlying
    }
    const fee = isLocal ? '0' : '1000000000000000' // 0.1% to be safe, oracle updates every ~0.49% price change
    const params = await deployer.deploy(isLocal ? MockParameters : Parameters, fee, modelAddr, priceAddr, hedge.address, leverage.address, underlyingAddr)
    const swap = await deployProxy(Swap, [params.address], { deployer, kind: "uups" })

    await hedge.grantRole(await hedge.MINTER_ROLE.call(), swap.address)
    await hedge.grantRole(await hedge.DEFAULT_ADMIN_ROLE.call(), timelockAddr)
    await hedge.revokeRole(await hedge.DEFAULT_ADMIN_ROLE.call(), accounts[0])
    await leverage.grantRole(await leverage.MINTER_ROLE.call(), swap.address)
    await leverage.grantRole(await leverage.DEFAULT_ADMIN_ROLE.call(), timelockAddr)
    await leverage.revokeRole(await leverage.DEFAULT_ADMIN_ROLE.call(), accounts[0])

    if (!isLocal) {
      await swap.transferOwnership(timelockAddr)
    }

    const filename = `deployments-${consts.addrs[network].name}.json`
    let deployments
    try {
      deployments = JSON.parse(fs.readFileSync(filename))
    } catch (e) {
      if (e.code !== 'ENOENT') {
        throw e
      }
      deployments = {}
    }
    if (isLocal) {
      deployments.hedge = hedge.address
      deployments.leverage = leverage.address
    } else {
      deployments[consts.hedgeSymbol] = hedge.address
      deployments[consts.leverageSymbol] = leverage.address
    }
    deployments[consts.swapName] = swap.address
    deployments.timelock = timelockAddr
    fs.writeFileSync(filename, JSON.stringify(deployments, undefined, 2))
  }
};
