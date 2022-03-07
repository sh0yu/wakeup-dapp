
const Wakeup = artifacts.require("Wakeup");
// const utils = require("./utils/utils.js");
// const time = require("./utils/time.js");
// const DEPOSIT = 1 ether;
// const REWARD = 0.9 ether;
const CONT_DAYS_MAX = 3;
// const INVALID_WAKUP_TIME = 15 minutes;
// const NEXT_INVALID_TIME = 0 minutes;

contract("Wakeup", (accounts) => {
    let [alice, bob] = accounts;
    let contractInstance;
    beforeEach(async () => {
        contractInstance = await Wakeup.new();
    });
    context("", async ()=> {
        it("should be able to set wakeup time", async () => {
            const nowTime = Math.trunc(new Date().getTime()/1000);
            const result = await contractInstance.setWakeupTime(nowTime, { from: alice, value: web3.utils.toWei("1", "ether") });
            const wakeupTimeReceived = await contractInstance.getWakeupTime(alice);
            assert.equal(result.receipt.status, true);
            assert.equal(nowTime, wakeupTimeReceived);
        });
        it("should be able to increment", async () => {
            const nowTime = Math.trunc(new Date().getTime()/1000);
            await contractInstance.setWakeupTime(nowTime, { from: alice, value: web3.utils.toWei("1", "ether") });
            for (let i = 0; i < (CONT_DAYS_MAX-1); i++){
                const result = await contractInstance.incrementContDays({ from: alice });
                const contDays = await contractInstance.getContDays(alice);
                assert.equal(result.receipt.status, true);
                assert.equal(contDays, i+1);
            }
        })
        it("should be able to get reward", async () => {
            const nowTime = Math.trunc(new Date().getTime()/1000);
            await contractInstance.setWakeupTime(nowTime, { from: alice, value: web3.utils.toWei("1", "ether") });
            for (let i = 0; i < CONT_DAYS_MAX; i++){
                await contractInstance.incrementContDays({ from: alice });
            }
            const contDays = await contractInstance.getContDays(alice);
            const rewardFlag = await contractInstance.getRewardFlag(alice);
            assert.equal(contDays, 0);
            assert.equal(rewardFlag, true)
        })
    })
})
