const BN = web3.utils.BN
const MockMath = artifacts.require("MockMath")

const to26 = amount => (new BN(amount*10000000000)).mul((new BN(10)).pow(new BN(16)))

contract("MathUtils", accounts => {
    let math;

    beforeEach(async () => {
        math = await MockMath.deployed()
    })


    it("should correctly calculate 1.2^6", async () => {
        const res = await math.testPow.call(to26(1.2), 6);
        const result = await math.testGasPow(to26(1.2), 6);
        console.log("      gas: ", result.receipt.gasUsed - 21000)

        assert.equal(res.toString(), to26(2.985984).toString())
    })

    it("should correctly calculate (1+(.2/8765.82))^2458 accurate to 18 decimals", async () => {
        const res = await math.testPow.call(new BN("100002281589172490400000000"), 2458);
        const result = await math.testGasPow(new BN("100002281589172490400000000"), 2458);
        console.log("      gas: ", result.receipt.gasUsed - 21000)

        assert.equal(res.toString().substring(0, 19), "1057683164451676367")
    })

    it("should correctly calculate (1+(.5/8765.82))^876500 accurate to 20 digits", async () => {
        const res = await math.testPow.call(new BN("100005703972931226000000000"), 876500);
        const result = await math.testGasPow(new BN("100005703972931226000000000"), 876500);
        console.log("      gas: ", result.receipt.gasUsed - 21000)

        assert.equal(res.toString().substring(0, 20), "51531593041332642127")
    })

    it("should correctly calculate (e^(.01/8765.82))^8765 accurate to 18 decimals", async () => {
        const res = await math.testPow.call(new BN("100000114079523695200000000"), 8765);
        const result = await math.testGasPow(new BN("100000114079523695200000000"), 8765);
        console.log("      gas: ", result.receipt.gasUsed - 21000)

        assert.equal(res.toString().substring(0, 19), "1010049222231608299")
    })

    it("should calculate (e^(.01/8765.82))^876569 accurate to 18 decimals", async () => {
        const res = await math.testPow.call(new BN("100000114079523695200000000"), 876569);
        const result = await math.testGasPow(new BN("100000114079523695200000000"), 876569);
        console.log("      gas: ", result.receipt.gasUsed - 21000)

        assert.equal(res.toString().substring(0, 19), "2718241515743398118")
    })
    
})