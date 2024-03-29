const BN = web3.utils.BN
const MockPrice = artifacts.require("MockPrice")
const MockModel = artifacts.require("MockModel")
const Swap = artifacts.require("Swap")
const { time } = require('openzeppelin-test-helpers');

const toWei = amount => (new BN(amount*10000000000)).mul((new BN(10)).pow(new BN(8)))

contract("Interest", accounts => {
    let interest;
    let feed;
    let model;

    beforeEach(async () => {
        interest = await Swap.deployed()
        feed  = await MockPrice.deployed()
        model = await MockModel.deployed()
    })

    it("should correctly calculate accrewed interest after 3 hours", async () => {
        await time.increase(time.duration.seconds(3600*10.2));
        await model.setInterest(new BN("0000022815890000000")) // .2/8765.82
        await interest.updateInterestRate()
        await time.increase(time.duration.seconds(3600*3));
        const multiplier = await interest.accrewedMul.call()

        assert.equal(multiplier.toString().substring(0, 19), "1000068449231706386")
    })

    it("should correctly calculate accrewed interest after 20 hours after it's changed", async () => {
        await model.setInterest(new BN("0000003422383758735")) // .03/8765.82
        await interest.updateInterestRate()
        await time.increase(time.duration.seconds(3600*20));
        const multiplier = await interest.accrewedMul.call()

        assert.equal(multiplier.toString().substring(0, 19), "1000136903817684905")
    })

    it("should correctly calculate float value at the current interest rate", async () => {
        await feed.setPrice(toWei(1000));
        const rate = await interest.hedgeValueNominal(toWei(1));
        const multiplier = await interest.accrewedMul.call()
        const expected = multiplier.mul(new BN('10000000000')).div(toWei(1000))

        assert.equal(rate.toString(), expected.toString())
    })
})