<template>
    <div>
        <div class="container pt-2 border rounded bg-light" style="max-width:700px">
            <div class="row m-2 justify-content-center">
                <button class="col-8 btn btn-primary" v-if="depositFlag && !checkOverslept()" v-on:click="wakeup()">目覚めた!</button>
                <span class="col-8 container" style="z-index:1" v-if="depositFlag && checkOverslept()" data-bs-toggle="tooltip" title="起床時刻を再セットしてください">
                    <button class="btn btn-outline-secondary" style="width:100%;z-index:2" v-if="depositFlag && checkOverslept()" disabled>あなたは寝坊しました</button>
                </span>
                <button class="col-8 btn btn-success" v-if="rewardFlag" v-on:click="receiveReward()">報酬を受け取る!</button>
            </div>
            <div class="row m-2 justify-content-center">
                <Datepicker class="col-6" v-model="dateInput" position="left" monthNameFormat="long" locale="jp" showNowButton nowButtonLabel="現在時刻" selectText="決定" cancelText="キャンセル" required>
                    <template #calendar-header="{ index, day }">
                        <div :class="index === 5 || index === 6 ? 'red-color' : ''">
                            {{ day }}
                        </div>
                    </template>
                </Datepicker>
                <button class="col-6 btn btn-secondary" v-if="!checkOverslept() && (depositFlag || rewardFlag)" data-bs-toggle="modal" data-bs-target="#setWakeupTimeModal">起床時刻をリセット</button>
                <button class="col-6 btn btn-primary" v-if="checkOverslept() || (!depositFlag && !rewardFlag)" data-bs-toggle="modal" data-bs-target="#setWakeupTimeModal">起床時刻をセット</button>
            </div>
            <div class="row m-2 justify-content-center">
                <div class="col">
                    <ul class="list-group">
                        <li class="list-group-item">起床予定時刻: {{ wakeupTimeToLocale() }}</li>
                        <li class="list-group-item">起床報告期限: {{ wakeupTimeToToLocale() }}</li>
                        <li class="list-group-item">継続日数: {{ contDays }}日間</li>
                        <li class="list-group-item">報酬状況: {{ rewardFlag? "獲得!" : "未獲得" }}</li>
                        <!-- <li class="list-group-item">最終更新時刻: {{ lastUpdatedToLocale() }}</li> -->
                    </ul>
                </div>
            </div>
            <div class="row m-3 justify-content-center">
                <div class="col">
                    みんなから集まったデポジット: {{ balance }} ETH
                </div>
            </div>
            <!-- <footer class="row footer mt-3 justify-content-center">
                    <span class="text-muted">あさかつアプリ by Shoyu &copy; All Rights Reserved.</span>
            </footer> -->
        </div>
        <!-- Modal -->
        <div class="modal fade" id="setWakeupTimeModal" tabindex="-1" aria-labelledby="setWakeupTimeModalLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="setWakeupTimeModalLabel">注意事項を確認してください</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    {{ getWakeupHourMinute }}に起床時刻をセットします<br>
                    初回は {{ getWakeupDay }} {{ getWakeupHourMinute }}です<br>
                    起きたら「目覚めた!」ボタンを押してください<br>
                    1度でも寝坊をするとデポジットは没収されます<br>
                    7日間、早起きを頑張りましょう<br>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">キャンセル</button>
                    <button type="button" class="btn btn-primary" data-bs-dismiss="modal" v-on:click="setWakeupTime()">同意する</button>
                </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import detectEthereumProvider from '@metamask/detect-provider'
import text from "raw-loader!../../public/Wakeup.txt"
import { Tooltip } from "bootstrap"
new Tooltip(document.body, {
    selector: "[data-bs-toggle='tooltip']",
})

const Web3 = require("web3")
var web3
var metamask
var wakeupContract
var userAccount

const cryptoZombiesABI = JSON.parse(text).abi
const cryptoZombiesAddress = "0x2Dd26babdcF39b7A1cff42dbA470BA14027b7087"

export default {
    name: "TopPage",
    data() {
        return {
            dateInput: new Date(),
            balance: 0,
            wakeupTime: new Date(0),
            wakeupTimeTo: new Date(0),
            lastUpdated: new Date(0),
            contDays: 0,
            depositFlag: false,
            rewardFlag: false
        }
    },
    computed: {
        dateToEpoch() {
            return Math.trunc(this.dateInput.getTime()/1000/60)*60
        },
        getWakeupDay() {
            const dayOfWeek = ["日","月","火","水","木","金","土"]
            const day = this.dateInput.getDay()
            return this.dateInput.getFullYear()+"/"+(this.dateInput.getMonth()+1)+"/"+this.dateInput.getDate()+"("+dayOfWeek[day]+")"
        },
        getWakeupHourMinute() {
            return this.dateInput.getHours().toString().padStart(2,'0') + ":" + this.dateInput.getMinutes().toString().padStart(2,'0')
        }
    },
    methods:{
        async startApp() {
            if (metamask !== window.ethereum) {
                console.error('Do you have multiple wallets installed?')
            }
            web3 = new Web3(Web3.givenProvider || "ws://localhost:7545")
            wakeupContract = new web3.eth.Contract(cryptoZombiesABI, cryptoZombiesAddress)
            console.log(web3.eth)
            console.log(wakeupContract)
            console.log(web3.eth.accounts)
            console.log("metamask.connectted:" + metamask.isConnected())
            metamask.request({ method: 'eth_requestAccounts' })
            .then(this.handleUserAccountChanged)
            .catch((error)=>{
                if(error.code === 4001) {
                    console.log('Please connect to MetaMask.')
                }
                console.log(error)
            })
            metamask.on('accountsChanged', this.handleUserAccountChanged)
        },
        handleUserAccountChanged(accounts) {
            console.log("accounts changed detected: " + accounts[0])
            userAccount = accounts[0]
            this.displayContDays()
        },
        displayContDays() {
            this.checkOwnerInfo(),
            this.checkContractBalance()
            this.checkOverslept
        },
        checkOwnerInfo(){
            this.getWakeupTime()
            .then((wakeupTime)=>{
                if(wakeupTime != 0){
                    this.dateInput = new Date(wakeupTime*1000)
                }
                this.wakeupTime.setTime(wakeupTime*1000)
                console.log(this.wakeupTime)
            })
            .catch(err=>{console.log(err)})
            this.getWakeupTimeTo()
            .then((wakeupTimeTo)=>{
                this.wakeupTimeTo.setTime(wakeupTimeTo*1000)
                console.log(this.wakeupTimeTo)
            })
            .catch(err=>{console.log(err)})
            this.getContDays()
            .then((contDays)=>{
                this.contDays = contDays
                console.log(this.contDays)
            })
            .catch(err=>{console.log(err)})
            this.getDepositFlag()
            .then((depositFlag)=>{
                this.depositFlag = depositFlag
                console.log(this.depositFlag)
            })
            .catch(err=>{console.log(err)})
            this.getRewardFlag()
            .then((rewardFlag)=>{
                this.rewardFlag = rewardFlag
                console.log(this.rewardFlag)
            })
            .catch(err=>{console.log(err)})
            this.getLastUpdated()
            .then((lastUpdated)=>{
                this.lastUpdated.setTime(lastUpdated*1000)
                console.log(this.lastUpdated)
            })
            .catch(err=>{console.log(err)})
        },
        checkContractBalance(){
            this.getBalance()
            .then((balance)=>{
                this.balance = web3.utils.fromWei(balance)
                console.log(this.balance)
            })
            .catch(err=>{console.log(err)})
        },
        wakeup() {
            wakeupContract.methods.incrementContDays()
            .send({ from: userAccount })
            .on("receipt", (receipt)=>{
                console.log(receipt)
                this.displayContDays()
            })
            .on("error", (error)=>{
                console.log(error.message)
                console.log(error)
            });
        },
        setWakeupTime() {
            wakeupContract.methods.setWakeupTime(this.dateToEpoch)
            .send({ from: userAccount, value: web3.utils.toWei("0.01", "ether") })
            .on("receipt", (receipt)=>{
                console.log(receipt)
                console.log("set wakeup time")
                this.displayContDays()
            })
        },
        receiveReward() {
            this.getRewardFlag()
            .then((rewardFlag)=>{
                if(!rewardFlag){
                    console.log("You have not gotten reward.")
                    return
                }
                wakeupContract.methods.receiveReward()
                .send({ from: userAccount })
                .on("receipt", (receipt)=>{
                    console.log(receipt)
                    console.log("reward received.")
                    this.displayContDays()
                })
                .on("error", (error)=>{
                    console.log(error)
                })
            })
        },
        checkOverslept() {
            return this.wakeupTimeTo.getTime() < (new Date()).getTime()
        },
        wakeupTimeToLocale(){
            if(this.wakeupTime.getTime() == 0){
                return "未設定"
            }else{
                return this.wakeupTime.toLocaleString("ja").slice(0,-3)
            }
        },
        wakeupTimeToToLocale(){
            if(this.wakeupTime.getTime() == 0){
                return "未設定"
            }else{
               return this.wakeupTimeTo.toLocaleString("ja").slice(0,-3)
            }
        },
        lastUpdatedToLocale(){
            if(this.wakeupTime.getTime() == 0){
                return "未設定"
            }else{
                return this.lastUpdated.toLocaleString("ja")
            }
        },
        getLastUpdated() {
            return wakeupContract.methods.getLastUpdated(userAccount).call()
        },
        getWakeupTime() {
            return wakeupContract.methods.getWakeupTime(userAccount).call()
        },
        getWakeupTimeTo() {
            return wakeupContract.methods.getWakeupTimeTo(userAccount).call()
        },
        getContDays() {
            return wakeupContract.methods.getContDays(userAccount).call()
        },
        getDepositFlag() {
            return wakeupContract.methods.getDepositFlag(userAccount).call()
        },
        getRewardFlag() {
            return wakeupContract.methods.getRewardFlag(userAccount).call()
        },
        getBalance() {
            return wakeupContract.methods.getBalance().call()
        }
    },
    mounted: async function() {
        metamask = await detectEthereumProvider()
        if (metamask) {
            console.log('MetaMask installed')
            this.startApp()
        } else {
            console.log('Please install MetaMask!')
        }
    },
    unmounted: function() {
        metamask.removeListener('accountsChanged', this.handleUserAccountChanged)
    }
}
</script>

<style scoped>
  .red-color {
      color: red;
  }
  .bg-img {
      background-image: url("../assets/background.jpeg")
  }
</style>