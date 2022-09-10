const { BN } = require("openzeppelin-test-helpers")

const LinearModel = artifacts.require("LinearModel")

const toWei = amount => (new BN(amount * 10000000000)).mul((new BN(10)).pow(new BN(8)))


const M = 0.2
const B = 0.28
//0.01 / 8765.82
const step = toWei(0.001).mul(toWei(1)).div(toWei(8765.82)) 

// y = (Mx - B) / 8765.82
const f = (collRatio) => toWei(M).mul(toWei(collRatio)).div(toWei(1)).sub(toWei(B)).mul(toWei(1)).div(toWei(8765.82))
// ((n + step/2) / step) * step
const round = (n) => n.div(step).mul(step)

const expected = (collRatio) => round(f(collRatio))

contract('LinearModel', async () => {
    beforeEach(async () => {
        model = await LinearModel.deployed()
    })

    it('should correctly calculate interest rate when collateral ratio is 1', async () => {
        const rate = await model.getInterestRate.call(toWei(1), toWei(1))
        assert.equal(rate.toString(), expected(1).toString())
    })

    // should be 0
    it('should correctly calculate interest rate when collateral ratio is 1.4', async () => {
        const rate = await model.getInterestRate.call(toWei(1.4), toWei(1))
        assert.equal(rate.toString(), expected(1.4).toString())
    })
    
    it('should correctly calculate interest rate when collateral ratio is 1.5', async () => {
        const rate = await model.getInterestRate.call(toWei(1.5), toWei(1))
        assert.equal(rate.toString(), expected(1.5).toString())
    })

    it('should correctly calculate interest rate when collateral ratio is 2', async () => {
        const rate = await model.getInterestRate.call(toWei(2), toWei(1))
        assert.equal(rate.toString(), expected(2).toString())
    })

    it('should correctly calculate interest rate when collateral ratio is 1.048796556', async () => {
        const rate = await model.getInterestRate.call(toWei(1.048796556), toWei(1))
        assert.equal(rate.toString(), expected(1.048796556).toString())
    })
})