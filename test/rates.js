const BN = web3.utils.BN
const MockPriceFeed = artifacts.require("MockPriceFeed")
const MockModel = artifacts.require("MockModel")
const Rates = artifacts.require("Swap")
const { time } = require('openzeppelin-test-helpers');

const toWei = amount => (new BN(amount*10000000000)).mul((new BN(10)).pow(new BN(8)))

contract("Rates", accounts => {
    let rates;
    let feed;
    let model;

    beforeEach(async () => {
        rates = await Rates.deployed()
        feed  = await MockPriceFeed.deployed()
        model = await MockModel.deployed()
    })

    it("should restrict acccess to setTolerance()", async () => {
        try {
            await rates.setTolerance(toWei(2), { from: accounts[1] });
        } catch(e) {
            return;
        }
        assert.fail();
    })

    it("should restrict acccess to setInterest()", async () => {
        try {
            await rates.setInterest(toWei(2), { from: accounts[1] });
        } catch(e) {
            return;
        }
        assert.fail();
    })

    it("should restrict acccess to setMaxPriorityFee()", async () => {
        try {
            await rates.setMaxPriorityFee(toWei(2), { from: accounts[1] });
        } catch(e) {
            return;
        }
        assert.fail();
    })

    it("should correctly calculate accrewed interest after 3 hours", async () => {
        await time.increase(time.duration.seconds(3600*10.2));
        await model.setInterest(new BN("0000022815890000000")) // .2/8765.82
        await rates.updateInterest()
        await time.increase(time.duration.seconds(3600*3));
        const multiplier = await rates.accIntMul.call()

        assert.equal(multiplier.toString().substring(0, 19), "1000068449231706386")
    })

    it("should correctly calculate accrewed interest after 20 hours after it's changed", async () => {
        await model.setInterest(new BN("0000003422383758735")) // .03/8765.82
        await rates.updateInterest()
        await time.increase(time.duration.seconds(3600*20));
        const multiplier = await rates.accIntMul.call()

        assert.equal(multiplier.toString().substring(0, 19), "1000136903817684905")
    })

    it("should correctly calculate fixed value at the current interest rate", async () => {
        await feed.setPrice(toWei(1000));
        const rate = await rates.fixedValue.call();
        const multiplier = await rates.accIntMul.call()
        const expected = toWei(1000).mul((new BN(10)).pow(new BN(26))).div(multiplier)

        assert.equal(rate.toString(), expected.toString())
    })
})