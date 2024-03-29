const fs = require('fs')
const deployments = JSON.parse(fs.readFileSync('deployments-test.json'))
const BN = web3.utils.BN

const Swap = artifacts.require("Swap")
const MockWETH = artifacts.require("MockWETH")
const Token = artifacts.require("Token")
const MockPrice = artifacts.require("MockPrice");
const MockParameters = artifacts.require("MockParameters")

const toWei = amount => (new BN(amount*10000000000)).mul((new BN(10)).pow(new BN(8)))

contract("Swap", accounts => {
    let swap;
    let weth;
    let eusd;
    let leth;

    beforeEach(async () => {
        params = await MockParameters.deployed()
        swap = await Swap.deployed()
        weth = await MockWETH.deployed()
        eusd = await Token.at(deployments.hedge)
        leth = await Token.at(deployments.leverage)
        feed = await MockPrice.deployed()
    })


    it("should mint 10,000 EUSD in exchange for 10 WETH", async () => {
        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await weth.approve(swap.address, toWei(10))
        await swap.buyHedge(toWei(10000), accounts[0])

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(-10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(10000).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(0).toString());
    })


    it("should burn 10,000 EUSD and return 10 WETH", async () => {
        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await eusd.approve(swap.address, toWei(10000))
        await swap.sellHedge(toWei(10000), accounts[0])

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(-10000).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(0).toString());
    })


    it("should mint 10 LETH in exchange for 10 WETH", async () => {
        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await weth.approve(swap.address, toWei(10))
        await swap.buyLeverage(toWei(10), accounts[0])

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(-10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(0).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(10).toString());
    })


    it("should burn 10 LETH and return 10 WETH", async () => {
        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        const eusdBalBefore = await eusd.balanceOf.call(accounts[0])
        const lethBalBefore = await leth.balanceOf.call(accounts[0])

        await leth.approve(swap.address, toWei(10))
        await swap.sellLeverage(toWei(10), accounts[0])

        const wethBalAfter = await weth.balanceOf.call(accounts[0])
        const eusdBalAfter = await eusd.balanceOf.call(accounts[0])
        const lethBalAfter = await leth.balanceOf.call(accounts[0])

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), toWei(10).toString());
        assert.equal(eusdBalAfter.sub(eusdBalBefore).toString(), toWei(0).toString());
        assert.equal(lethBalAfter.sub(lethBalBefore).toString(), toWei(-10).toString());
    })


    it("should return rest of WETH to EUSD holders if undercollateralized", async () => {
        const targetBefore = 1000;

        await weth.approve(swap.address, toWei( 2.077), { from: accounts[0] })
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  1.304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(   11), accounts[3], { from: accounts[3] })
        await swap.buyHedge (toWei( 2077), accounts[0], { from: accounts[0] })
        await swap.buyHedge (toWei(10101), accounts[1], { from: accounts[1] })
        await swap.buyHedge (toWei(  304), accounts[2], { from: accounts[2] })

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

        await feed.setPrice(toWei(5))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await swap.sellHedge(toWei( 2077), accounts[0], { from: accounts[0] })
        await swap.sellHedge(toWei(10101), accounts[1], { from: accounts[1] })
        await swap.sellHedge(toWei(  304), accounts[2], { from: accounts[2] })

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
        await swap.sellLeverage(toWei(11), accounts[3], { from: accounts[3] })          // reset balances to 0
        await feed.setPrice(toWei(1000))
    })


    it("should maintian peg if WETH price drops", async () => {
        await weth.approve(swap.address, toWei( 2.077), { from: accounts[0] })
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(   11), accounts[3], { from: accounts[3] });
        await swap.buyHedge (toWei( 2077), accounts[0], { from: accounts[0] });
        await swap.buyHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(  304), accounts[2], { from: accounts[2] });

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

        await feed.setPrice(toWei(777))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await leth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.sellHedge (toWei( 2077), accounts[0], { from: accounts[0] });
        await swap.sellHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(  304), accounts[2], { from: accounts[2] });
        await swap.sellLeverage(toWei(   11), accounts[3], { from: accounts[3] });

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


    it("should maintian peg if WETH price rises", async () => {
        await feed.setPrice(toWei(1000))
        await weth.approve(swap.address, toWei( 2.077), { from: accounts[0] })
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(   11), accounts[3], { from: accounts[3] });
        await swap.buyHedge (toWei( 2077), accounts[0], { from: accounts[0] });
        await swap.buyHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(  304), accounts[2], { from: accounts[2] });

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

        await feed.setPrice(toWei(1400))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await leth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.sellHedge (toWei( 2077), accounts[0], { from: accounts[0] });
        await swap.sellHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(  304), accounts[2], { from: accounts[2] });
        await swap.sellLeverage(toWei(   11), accounts[3], { from: accounts[3] });

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


    it("should give  2x loss to LETH holders if WETH price drops with system at a 2.0 coll ratio", async () => {
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await feed.setPrice(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(15), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(   25), accounts[0], { from: accounts[0] });
        await swap.buyLeverage(toWei(   75), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(15000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei(85000), accounts[3], { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await feed.setPrice(toWei(600))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(15000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(   25), accounts[0], { from: accounts[0] });
        await swap.sellLeverage(toWei(   75), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(15000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei(85000), accounts[3], { from: accounts[3] });

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


    it("should give  3x loss to LETH holders if WETH price drops with system at a 1.5 coll ratio", async () => {
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await feed.setPrice(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.buyLeverage(toWei(    75), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei( 85000), accounts[3], { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await feed.setPrice(toWei(800))
        await leth.approve(swap.address, toWei(    25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(    75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei( 85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.sellLeverage(toWei(    75), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei( 85000), accounts[3], { from: accounts[3] });

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


    it("should give  2x gain to LETH holders if WETH price rises with system at a 2.0 coll ratio", async () => {
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await feed.setPrice(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(15), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(   25), accounts[0], { from: accounts[0] });
        await swap.buyLeverage(toWei(   75), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(15000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei(85000), accounts[3], { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await feed.setPrice(toWei(1500))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(15000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(   25), accounts[0], { from: accounts[0] });
        await swap.sellLeverage(toWei(   75), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(15000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei(85000), accounts[3], { from: accounts[3] });

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


    it("should give  3x gain to LETH holders if WETH price rises with system at a 1.5 coll ratio", async () => {
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await feed.setPrice(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.buyLeverage(toWei(    75), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei( 85000), accounts[3], { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await feed.setPrice(toWei(1600))
        await leth.approve(swap.address, toWei(   25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.sellLeverage(toWei(    75), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei( 85000), accounts[3], { from: accounts[3] });

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


    it("should give 11x gain to LETH holders if WETH price rises with system at a 1.1 coll ratio", async () => {
        const wethBalsBefore = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1]),
        ]

        await feed.setPrice(toWei(1000))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(885), { from: accounts[3] })
        await swap.buyLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.buyLeverage(toWei(    75), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei(885000), accounts[3], { from: accounts[3] });

        const wethBalsMid = [
            await weth.balanceOf.call(accounts[0]),
            await weth.balanceOf.call(accounts[1])
        ]

        await feed.setPrice(toWei(14000))
        await leth.approve(swap.address, toWei(    25), { from: accounts[0] })
        await leth.approve(swap.address, toWei(    75), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei(885000), { from: accounts[3] })
        await swap.sellLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.sellLeverage(toWei(    75), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei(885000), accounts[3], { from: accounts[3] });

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


    it("LETH buy  premium @ 1% target tolerance should equal gains from holding through a 1% increase in target price", async () => {
        // set up contract state
        await feed.setPrice(toWei(1000))
        await params.setFee(toWei(0))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await swap.buyHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei( 85000), accounts[3], { from: accounts[3] });
        await swap.buyLeverage(toWei(    25), accounts[0], { from: accounts[0] });

        const wethBalBefore = await weth.balanceOf.call(accounts[1])

        await params.setFee(toWei(0.01))
        await weth.approve(swap.address, toWei(150), { from: accounts[1] })
        await swap.buyLeverage(toWei(75), accounts[1], { from: accounts[1] });
        await weth.approve(swap.address, toWei(0), { from: accounts[1] })
        await params.setFee(toWei(0))
        await feed.setPrice(/*toWei(1000*1.01)*/new BN('1010101010101010101010'))
        await leth.approve(swap.address, toWei(   75), { from: accounts[1] })
        await swap.sellLeverage(toWei(75), accounts[1], { from: accounts[1] });

        const wethBalAfter = await weth.balanceOf.call(accounts[1])

        // reset contract state
        await leth.approve(swap.address, toWei(    25), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei( 85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.sellHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei( 85000), accounts[3], { from: accounts[3] });

        assert.equal(wethBalAfter.toString(), wethBalBefore.toString());
    })


    it("LETH sell premium @ 1% target tolerance should equal cost of holding through a 1% decrease in target price", async () => {
        // set up contract state
        await feed.setPrice(toWei(1000))
        await params.setFee(toWei(0))
        await weth.approve(swap.address, toWei(25), { from: accounts[0] })
        await weth.approve(swap.address, toWei(115), { from: accounts[2] })
        await weth.approve(swap.address, toWei(85), { from: accounts[3] })
        await weth.approve(swap.address, toWei(75), { from: accounts[1] })
        await swap.buyHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.buyHedge (toWei( 85000), accounts[3], { from: accounts[3] });
        await swap.buyLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.buyLeverage(toWei(    75), accounts[1], { from: accounts[1] });

        const wethBalBefore = await weth.balanceOf.call(accounts[1])

        await params.setFee(toWei(0.01))
        await leth.approve(swap.address, toWei(100), { from: accounts[1] })
        await swap.sellLeverage(toWei(75), accounts[1], { from: accounts[1] });
        await leth.approve(swap.address, toWei(0), { from: accounts[1] })

        const wethBalAfter1 = await weth.balanceOf.call(accounts[1])

        await params.setFee(toWei(0))
        //await feed.setPrice(toWei(1000*0.99))
        await feed.setPrice(new BN('990099009900990099010'))
        await weth.approve(swap.address, toWei(75), { from: accounts[1] });
        await swap.buyLeverage(toWei(75), accounts[1], { from: accounts[1] });

        const wethBalAfter2 = await weth.balanceOf.call(accounts[1])

        // reset contract state
        await leth.approve(swap.address, toWei(100), { from: accounts[1] })
        await swap.sellLeverage(toWei(75), accounts[1], { from: accounts[1] });
        await leth.approve(swap.address, toWei(0), { from: accounts[1] })
        await leth.approve(swap.address, toWei(    25), { from: accounts[0] })
        await eusd.approve(swap.address, toWei(115000), { from: accounts[2] })
        await eusd.approve(swap.address, toWei( 85000), { from: accounts[3] })
        await swap.sellLeverage(toWei(    25), accounts[0], { from: accounts[0] });
        await swap.sellHedge (toWei(115000), accounts[2], { from: accounts[2] });
        await swap.sellHedge (toWei( 85000), accounts[3], { from: accounts[3] });

        // const usdValBefore = 75*1000
        // const usdValAfterIfNoLev = 75 * 990.099009900990099
        // const usdValChange = usdValBefore - usdValAfterIfNoLev
        // const leverage = 3
        // const usdValAfter = usdValBefore - (usdValChange * leverage)
        // const expWethValAfter = toWei(usdValAfter).mul(toWei(1)).div(/*toWei(1000 * 0.99)*/new BN('990099009900990099010'))

        // assert.equal(wethBalAfter1.sub(wethBalBefore).toString(), expWethValAfter.toString());
        assert.equal(wethBalAfter2.toString(), wethBalBefore.sub(new BN(3)).toString());
    })


    it("EUSD buy  premium @ 1% target tolerance should equal gains from holding through a 1% decrease in target price", async () => {
        // set up contract state
        await feed.setPrice(toWei(1000))
        await params.setFee(toWei(0))
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(   11), accounts[3], { from: accounts[3] });
        await swap.buyHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(  304), accounts[2], { from: accounts[2] });

        const wethBalBefore = await weth.balanceOf.call(accounts[0])
        
        await params.setFee(toWei(0.01))
        await weth.approve(swap.address, toWei(3), { from: accounts[0] })
        await swap.buyHedge (toWei( 2077), accounts[0], { from: accounts[0] });
        await weth.approve(swap.address, toWei(0), { from: accounts[0] })
        //await feed.setPrice(toWei(1000*0.99))
        await feed.setPrice(new BN('990099009900990099010'))
        await params.setFee(toWei(0))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await swap.sellHedge (toWei( 2077), accounts[0], { from: accounts[0] });

        const wethBalAfter = await weth.balanceOf.call(accounts[0])

        // reset contract state
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await leth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.sellHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(  304), accounts[2], { from: accounts[2] });
        await swap.sellLeverage(toWei(   11), accounts[3], { from: accounts[3] });

        assert.equal(wethBalAfter.toString(), wethBalBefore.sub(new BN(1)).toString());
    })


    it("EUSD sell premium @ 1% target tolerance should equal cost of holding through a 1% increase in target price", async () => {
        // set up contract state
        await feed.setPrice(toWei(1000))
        await params.setFee(toWei(0))
        await weth.approve(swap.address, toWei(10.101), { from: accounts[1] })
        await weth.approve(swap.address, toWei(  .304), { from: accounts[2] })
        await weth.approve(swap.address, toWei(    11), { from: accounts[3] })
        await swap.buyLeverage(toWei(   11), accounts[3], { from: accounts[3] });
        await swap.buyHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.buyHedge (toWei(  304), accounts[2], { from: accounts[2] });
    
        await weth.approve(swap.address, toWei(2.077), { from: accounts[0] })
        await swap.buyHedge (toWei( 2077), accounts[0], { from: accounts[0] });

        const wethBalBefore = await weth.balanceOf.call(accounts[0])

        await params.setFee(toWei(0.01))
        await eusd.approve(swap.address, toWei( 2077), { from: accounts[0] })
        await swap.sellHedge (toWei( 2077), accounts[0], { from: accounts[0] });

        const wethBalAfter = await weth.balanceOf.call(accounts[0])

        // reset contract state
        await eusd.approve(swap.address, toWei(10101), { from: accounts[1] })
        await eusd.approve(swap.address, toWei(  304), { from: accounts[2] })
        await leth.approve(swap.address, toWei(   11), { from: accounts[3] })
        await swap.sellHedge (toWei(10101), accounts[1], { from: accounts[1] });
        await swap.sellHedge (toWei(  304), accounts[2], { from: accounts[2] });
        await swap.sellLeverage(toWei(   11), accounts[3], { from: accounts[3] });

        const expectedValue = (toWei(2077).mul(toWei(1)).div(/*toWei(1.01*1000)*/ new BN('1010101010101010101010')))

        assert.equal(wethBalAfter.sub(wethBalBefore).toString(), expectedValue.toString());
    })

    it("should restrict acccess to setParameters()", async () => {
        try {
            await rates.setParameters(toWei(2), { from: accounts[1] });
        } catch(e) {
            return;
        }
        assert.fail();
    })
})