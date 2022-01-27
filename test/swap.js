const fs = require('fs')
const contractAddrs = JSON.parse(fs.readFileSync('contractAddrs.json'))
const BN = web3.utils.BN

const Swap = artifacts.require("Swap")
const MockWETH = artifacts.require("MockWETH")
const Token = artifacts.require("Token")

const toWei = amount => (new BN(amount)).mul((new BN(10)).pow(new BN(18)))

contract("Swap", async accounts => {
    it("should mint 10,000 EUSD in exchange for 10 WETH", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)

        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await weth.approve(swap.address, toWei(10))
        await swap.buyHedge(toWei(10000))

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(-10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(10000).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(0).toString());
    })

    it("should burn 10,000 EUSD and return 10 WETH", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)

        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await eusd.approve(swap.address, toWei(10000))
        await swap.sellHedge(toWei(10000))

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(-10000).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(0).toString());
    })

    it("should mint 10 LETH in exchange for 10 WETH", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)

        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await weth.approve(swap.address, toWei(10))
        await swap.buyLeverage(toWei(10))

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(-10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(0).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(10).toString());
    })

    it("should burn 10 LETH and return 10 WETH", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)

        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await leth.approve(swap.address, toWei(10))
        await swap.sellLeverage(toWei(10))

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(0).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(-10).toString());
    })
})