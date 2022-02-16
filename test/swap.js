const fs = require('fs')
const contractAddrs = JSON.parse(fs.readFileSync('contractAddrs.json'))
const BN = web3.utils.BN

const Swap = artifacts.require("Swap")
const MockWETH = artifacts.require("MockWETH")
const Token = artifacts.require("Token")
const MockPrices = artifacts.require("MockPrices")

const toWei = amount => (new BN(amount*10000000000)).mul((new BN(10)).pow(new BN(8)))

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


    it("should return rest of WETH to EUSD holders when undercollateralized", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockPrices.deployed()

        
        const targetBefore = 1000;

        await weth.approve(swap.address, toWei( 2.077), { from: accounts[0] })
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.buyLeverage(toWei(11), { from: accounts[3] })
        await swap.buyHedge(toWei( 2077), { from: accounts[0] })
        await swap.buyHedge(toWei(10101), { from: accounts[1] })
        await swap.buyHedge(toWei(  304), { from: accounts[2] })

        const eusdBalsBefore = [
            await eusd.balanceOf.call(accounts[0]),
            await eusd.balanceOf.call(accounts[1]),
            await eusd.balanceOf.call(accounts[2])
        ]
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
            await weth.balanceOf.call(accounts[2])
        ]

        await prices.setTarget(toWei(5))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await swap.sellHedge(toWei( 2077), { from: accounts[0] })
        await swap.sellHedge(toWei(10101), { from: accounts[1] })
        await swap.sellHedge(toWei(  304), { from: accounts[2] })

        const eusdBalsAfter = [
            await eusd.balanceOf.call(accounts[0]),
            await eusd.balanceOf.call(accounts[1]),
            await eusd.balanceOf.call(accounts[2])
        ]
        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
            await weth.balanceOf.call(accounts[2])
        ]
        const totalEusd = 2077 + 10101 + 304
        const totalWeth = totalEusd/targetBefore + 11

        const expectedWethChange = eusdDeposited => (
            (toWei(eusdDeposited).mul(toWei(totalWeth))).div(toWei(totalEusd))
        )

        // Some expected results are off by 1 wei due to a difference in rounding errors
        // because values are calculated differently in the contract than they are here
        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange( 2077).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(10101).add(new BN(1)).toString());
        assert.equal(wethBalsAfter[2].sub(wethBalsBefore[2]).toString(), expectedWethChange(  304).add(new BN(1)).toString());
        assert.equal(eusdBalsAfter[0].sub(eusdBalsBefore[0]).toString(), toWei( -2077).toString());
        assert.equal(eusdBalsAfter[1].sub(eusdBalsBefore[1]).toString(), toWei(-10101).toString());
        assert.equal(eusdBalsAfter[2].sub(eusdBalsBefore[2]).toString(), toWei(  -304).toString());

        // reset contract state before next test
        await weth.transfer(swap.address, toWei(1), { from: accounts[3] }) // get contract out of stuck state due to overflow protection
        await leth.approve(swap.address, toWei(11), { from: accounts[3] })
        await swap.sellLeverage(toWei(11), { from: accounts[3] })          // reset balances to 0
        await prices.setTarget(toWei(1000))
    })


    it("should maintian peg when WETH price drops", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockPrices.deployed()

        await weth.approve(swap.address, toWei( 2.077), { from: accounts[0] })
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(11), { from: accounts[3] });
        await swap.buyHedge(toWei( 2077), { from: accounts[0] });
        await swap.buyHedge(toWei(10101), { from: accounts[1] });
        await swap.buyHedge(toWei(  304), { from: accounts[2] });

        const eusdBalsBefore = [
            await eusd.balanceOf.call(accounts[0]),
            await eusd.balanceOf.call(accounts[1]),
            await eusd.balanceOf.call(accounts[2])
        ]
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
            await weth.balanceOf.call(accounts[2])
        ]

        await prices.setTarget(toWei(777))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await leth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.sellHedge(toWei( 2077), { from: accounts[0] });
        await swap.sellHedge(toWei(10101), { from: accounts[1] });
        await swap.sellHedge(toWei(  304), { from: accounts[2] });
        await swap.sellLeverage(toWei(11), { from: accounts[3] });

        const eusdBalsAfter = [
            await eusd.balanceOf.call(accounts[0]),
            await eusd.balanceOf.call(accounts[1]),
            await eusd.balanceOf.call(accounts[2])
        ]
        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
            await weth.balanceOf.call(accounts[2])
        ]

        const expectedWethChange = eusdDeposited => (
            (toWei(eusdDeposited).mul(toWei(1))).div(toWei(777))
        )

        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange( 2077).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(10101).toString());
        assert.equal(wethBalsAfter[2].sub(wethBalsBefore[2]).toString(), expectedWethChange(  304).toString());
        assert.equal(eusdBalsAfter[0].sub(eusdBalsBefore[0]).toString(), toWei( -2077).toString());
        assert.equal(eusdBalsAfter[1].sub(eusdBalsBefore[1]).toString(), toWei(-10101).toString());
        assert.equal(eusdBalsAfter[2].sub(eusdBalsBefore[2]).toString(), toWei(  -304).toString());
    })


    it("should maintian peg when WETH price rises", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockRates.deployed()

        await prices.setTarget(toWei(1000))
        await weth.approve(swap.address, toWei( 2.077), { from: accounts[0] })
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(11), { from: accounts[3] });
        await swap.buyHedge(toWei( 2077), { from: accounts[0] });
        await swap.buyHedge(toWei(10101), { from: accounts[1] });
        await swap.buyHedge(toWei(  304), { from: accounts[2] });

        const eusdBalsBefore = [
            await eusd.balanceOf.call(accounts[0]),
            await eusd.balanceOf.call(accounts[1]),
            await eusd.balanceOf.call(accounts[2])
        ]
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
            await weth.balanceOf.call(accounts[2])
        ]

        await prices.setTarget(toWei(1400))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await leth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.sellHedge(toWei( 2077), { from: accounts[0] });
        await swap.sellHedge(toWei(10101), { from: accounts[1] });
        await swap.sellHedge(toWei(  304), { from: accounts[2] });
        await swap.sellLeverage(toWei(11), { from: accounts[3] });

        const eusdBalsAfter = [
            await eusd.balanceOf.call(accounts[0]),
            await eusd.balanceOf.call(accounts[1]),
            await eusd.balanceOf.call(accounts[2])
        ]
        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
            await weth.balanceOf.call(accounts[2])
        ]

        const expectedWethChange = eusdDeposited => (
            (toWei(eusdDeposited).mul(toWei(1))).div(toWei(1400))
        )

        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange( 2077).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(10101).toString());
        assert.equal(wethBalsAfter[2].sub(wethBalsBefore[2]).toString(), expectedWethChange(  304).toString());
        assert.equal(eusdBalsAfter[0].sub(eusdBalsBefore[0]).toString(), toWei( -2077).toString());
        assert.equal(eusdBalsAfter[1].sub(eusdBalsBefore[1]).toString(), toWei(-10101).toString());
        assert.equal(eusdBalsAfter[2].sub(eusdBalsBefore[2]).toString(), toWei(  -304).toString());
    })


    it("should give  2x leveraged loss to LETH holders when WETH price drops with system at a 2.0 coll ratio", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockRates.deployed()

        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await prices.setTarget(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(15), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(25), { from: accounts[0] });
        await swap.buyLeverage(toWei(75), { from: accounts[1] });
        await swap.buyHedge(toWei(15000), { from: accounts[2] });
        await swap.buyHedge(toWei(85000), { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await prices.setTarget(toWei(600))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(15000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(25), { from: accounts[0] });
        await swap.sellLeverage(toWei(75), { from: accounts[1] });
        await swap.sellHedge(toWei(15000), { from: accounts[2] });
        await swap.sellHedge(toWei(85000), { from: accounts[3] });

        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        const expectedWethChange = wethDeposited => {
            const EXPECTED_LEVERAGE = 2

            const usdValBefore       = (toWei(wethDeposited).mul(toWei(1000))).div(toWei(1))
            const usdValAfterIfNoLev = (toWei(wethDeposited).mul(toWei( 600))).div(toWei(1))
            const usdChangeIfNoLev   = usdValAfterIfNoLev.sub(usdValBefore)
            const expUsdChange       = usdChangeIfNoLev.mul(toWei(EXPECTED_LEVERAGE)).div(toWei(1))
            const expUsdValueAfter   = usdValBefore.add(expUsdChange)
            const expWethValAfter    = expUsdValueAfter.mul(toWei(1)).div(toWei(600))
            return expWethValAfter.sub(toWei(wethDeposited))
        }

        // Some expected results are off by 1 wei due to a difference in rounding errors
        // because values are calculated differently in the contract than they are here
        assert.equal(wethBalsMid[0].sub(wethBalsBefore[0]).toString(), toWei(-25).toString());
        assert.equal(wethBalsMid[1].sub(wethBalsBefore[1]).toString(), toWei(-75).toString());
        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange(25).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(75).add(new BN(1)).toString());
    })


    it("should give  3x leveraged loss to LETH holders when WETH price drops with system at a 1.5 coll ratio", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockRates.deployed()

        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await prices.setTarget(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(25), { from: accounts[0] });
        await swap.buyLeverage(toWei(75), { from: accounts[1] });
        await swap.buyHedge(toWei(115000), { from: accounts[2] });
        await swap.buyHedge(toWei(85000), { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await prices.setTarget(toWei(800))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(25), { from: accounts[0] });
        await swap.sellLeverage(toWei(75), { from: accounts[1] });
        await swap.sellHedge(toWei(115000), { from: accounts[2] });
        await swap.sellHedge(toWei(85000), { from: accounts[3] });

        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        const expectedWethChange = wethDeposited => {
            const EXPECTED_LEVERAGE = 3

            const usdValBefore       = (toWei(wethDeposited).mul(toWei(1000))).div(toWei(1))
            const usdValAfterIfNoLev = (toWei(wethDeposited).mul(toWei( 800))).div(toWei(1))
            const usdChangeIfNoLev   = usdValAfterIfNoLev.sub(usdValBefore)
            const expUsdChange       = usdChangeIfNoLev.mul(toWei(EXPECTED_LEVERAGE)).div(toWei(1))
            const expUsdValueAfter   = usdValBefore.add(expUsdChange)
            const expWethValAfter    = expUsdValueAfter.mul(toWei(1)).div(toWei(800))
            return expWethValAfter.sub(toWei(wethDeposited))
        }

        assert.equal(wethBalsMid[0].sub(wethBalsBefore[0]).toString(), toWei(-25).toString());
        assert.equal(wethBalsMid[1].sub(wethBalsBefore[1]).toString(), toWei(-75).toString());
        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange(25).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(75).toString());
    })


    it("should give  2x leveraged gain to LETH holders when WETH price rises with system at a 2.0 coll ratio", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockRates.deployed()

        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await prices.setTarget(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(15), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(25), { from: accounts[0] });
        await swap.buyLeverage(toWei(75), { from: accounts[1] });
        await swap.buyHedge(toWei(15000), { from: accounts[2] });
        await swap.buyHedge(toWei(85000), { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await prices.setTarget(toWei(1500))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(15000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(25), { from: accounts[0] });
        await swap.sellLeverage(toWei(75), { from: accounts[1] });
        await swap.sellHedge(toWei(15000), { from: accounts[2] });
        await swap.sellHedge(toWei(85000), { from: accounts[3] });

        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        const expectedWethChange = wethDeposited => {
            const EXPECTED_LEVERAGE = 2

            const usdValBefore       = (toWei(wethDeposited).mul(toWei(1000))).div(toWei(1))
            const usdValAfterIfNoLev = (toWei(wethDeposited).mul(toWei(1500))).div(toWei(1))
            const usdChangeIfNoLev   = usdValAfterIfNoLev.sub(usdValBefore)
            const expUsdChange       = usdChangeIfNoLev.mul(toWei(EXPECTED_LEVERAGE)).div(toWei(1))
            const expUsdValueAfter   = usdValBefore.add(expUsdChange)
            const expWethValAfter    = expUsdValueAfter.mul(toWei(1)).div(toWei(1500))
            return expWethValAfter.sub(toWei(wethDeposited))
        }

        // Some expected results are off by 1 wei due to a difference in rounding errors
        // because values are calculated differently in the contract than they are here
        assert.equal(wethBalsMid[0].sub(wethBalsBefore[0]).toString(), toWei(-25).toString());
        assert.equal(wethBalsMid[1].sub(wethBalsBefore[1]).toString(), toWei(-75).toString());
        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange(25).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(75).add(new BN(1)).toString());
    })


    it("should give  3x leveraged gain to LETH holders when WETH price rises with system at a 1.5 coll ratio", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockRates.deployed()

        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await prices.setTarget(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(25), { from: accounts[0] });
        await swap.buyLeverage(toWei(75), { from: accounts[1] });
        await swap.buyHedge(toWei(115000), { from: accounts[2] });
        await swap.buyHedge(toWei(85000), { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await prices.setTarget(toWei(1600))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(25), { from: accounts[0] });
        await swap.sellLeverage(toWei(75), { from: accounts[1] });
        await swap.sellHedge(toWei(115000), { from: accounts[2] });
        await swap.sellHedge(toWei(85000), { from: accounts[3] });

        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        const expectedWethChange = wethDeposited => {
            const EXPECTED_LEVERAGE = 3

            const usdValBefore       = (toWei(wethDeposited).mul(toWei(1000))).div(toWei(1))
            const usdValAfterIfNoLev = (toWei(wethDeposited).mul(toWei(1600))).div(toWei(1))
            const usdChangeIfNoLev   = usdValAfterIfNoLev.sub(usdValBefore)
            const expUsdChange       = usdChangeIfNoLev.mul(toWei(EXPECTED_LEVERAGE)).div(toWei(1))
            const expUsdValueAfter   = usdValBefore.add(expUsdChange)
            const expWethValAfter    = expUsdValueAfter.mul(toWei(1)).div(toWei(1600))
            return expWethValAfter.sub(toWei(wethDeposited))
        }

        assert.equal(wethBalsMid[0].sub(wethBalsBefore[0]).toString(), toWei(-25).toString());
        assert.equal(wethBalsMid[1].sub(wethBalsBefore[1]).toString(), toWei(-75).toString());
        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange(25).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(75).toString());
    })


    it("should give 11x leveraged gain to LETH holders when WETH price rises with system at a 1.1 coll ratio", async () => {
        const swap = await Swap.deployed()
        const weth = await MockWETH.deployed()
        const eusd = await Token.at(contractAddrs.EUSD)
        const leth = await Token.at(contractAddrs.LETH)
        const prices = await MockRates.deployed()

        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await prices.setTarget(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(885), { from: accounts[3] })
        await swap.buyLeverage(toWei(25), { from: accounts[0] });
        await swap.buyLeverage(toWei(75), { from: accounts[1] });
        await swap.buyHedge(toWei(115000), { from: accounts[2] });
        await swap.buyHedge(toWei(885000), { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await prices.setTarget(toWei(14000))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(885000), { from: accounts[3] })
        await swap.sellLeverage(toWei(25), { from: accounts[0] });
        await swap.sellLeverage(toWei(75), { from: accounts[1] });
        await swap.sellHedge(toWei(115000), { from: accounts[2] });
        await swap.sellHedge(toWei(885000), { from: accounts[3] });

        const wethBalsAfter = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        const expectedWethChange = wethDeposited => {
            const EXPECTED_LEVERAGE = 11

            const usdValBefore       = (toWei(wethDeposited).mul(toWei(1000))).div(toWei(1))
            const usdValAfterIfNoLev = (toWei(wethDeposited).mul(toWei(14000))).div(toWei(1))
            const usdChangeIfNoLev   = usdValAfterIfNoLev.sub(usdValBefore)
            const expUsdChange       = usdChangeIfNoLev.mul(toWei(EXPECTED_LEVERAGE)).div(toWei(1))
            const expUsdValueAfter   = usdValBefore.add(expUsdChange)
            const expWethValAfter    = expUsdValueAfter.mul(toWei(1)).div(toWei(14000))
            return expWethValAfter.sub(toWei(wethDeposited))
        }

        // Some expected results are off by 1 wei due to a difference in rounding errors
        // because values are calculated differently in the contract than they are here
        assert.equal(wethBalsMid[0].sub(wethBalsBefore[0]).toString(), toWei(-25).toString());
        assert.equal(wethBalsMid[1].sub(wethBalsBefore[1]).toString(), toWei(-75).toString());
        assert.equal(wethBalsAfter[0].sub(wethBalsBefore[0]).toString(), expectedWethChange(25).toString());
        assert.equal(wethBalsAfter[1].sub(wethBalsBefore[1]).toString(), expectedWethChange(75).add(new BN(1)).toString());
    })

    
})