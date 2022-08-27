const BN = web3.utils.BN
const MockPriceFeed = artifacts.require("MockPriceFeed")
const Rates = artifacts.require("Rates")
const { time } = require('openzeppelin-test-helpers');

const toWei = amount => (new BN(amount*10000000000)).mul((new BN(10)).pow(new BN(8)))

contract("Rates", accounts => {
    let rates;
    let feed;

    beforeEach(async () => {
        rates = await Rates.deployed()
        feed = await MockPriceFeed.deployed()
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
        await rates.setInterest(new BN("1000022815890000000")) // .2/8765.82
        await time.increase(time.duration.seconds(3600*3.5));
        const multiplier = await rates.accIntMul.call()

        assert.equal(multiplier.toString().substring(0, 19), "1000068449231706386")
    })

    it("should correctly calculate accrewed interest after 20 hours after it's changed", async () => {
        await rates.setInterest(new BN("1000003422383758735")) // .03/8765.82
        await time.increase(time.duration.seconds(3600*20.1));
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