<template>
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
                5日間、早起きを頑張りましょう<br>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">キャンセル</button>
                <button type="button" class="btn btn-primary" data-bs-dismiss="modal" @click="setWakeupTime()">同意する</button>
            </div>
            </div>
        </div>
    </div>
    <div class="bg-img vh-100 vw-100">
        <!-- Notification Toasts -->
        <div class="alert alert-success fade show" v-show="setWakeupTimeSuccessAlert" role="alert">起床時刻をセットしました
            <button type="button" class="btn-close" @click="setWakeupTimeSuccessAlert = false"></button>
        </div>
        <div class="alert alert-warning fade show" v-show="setWakeupTimeFailedAlert" role="alert">もう一度 起床事項をセットしてください
            <button type="button" class="btn-close" @click="setWakeupTimeFailedAlert = false"></button>
        </div>
        <div class="alert alert-success fade show" v-show="wakeupSuccessAlert" role="alert">おはようございます!良い1日を!
            <button type="button" class="btn-close" @click="wakeupSuccessAlert = false"></button>
        </div>
        <div class="alert alert-warning fade show" v-show="wakeupFailedAlert" role="alert">もう一度 目覚めたボタンを押してください
            <button type="button" class="btn-close" @click="wakeupFailedAlert = false"></button>
        </div>
        <div class="alert alert-success fade show" v-show="receiveRewardSuccessAlert" role="alert">報酬を受け取りました!
            <button type="button" class="btn-close" @click="receiveRewardSuccessAlert = false"></button>
        </div>
        <div class="alert alert-warning fade show" v-show="receiveRewardFailedAlert" role="alert">もう一度 報酬を受け取るボタンを押してください
            <button type="button" class="btn-close" @click="receiveRewardFailedAlert = false"></button>
        </div>
        <div class="container mt-3 pt-2 border rounded bg-light shadow" style="max-width:700px">
            <div class="row m-2 justify-content-center">
                <button class="col-8 btn btn-primary" v-show="depositFlag && checkStillSleep" disabled>まだ寝ている時間です</button>
                <button class="col-8 btn btn-primary" v-show="depositFlag && !checkStillSleep && !checkOverslept" @click="wakeup()">
                    <span class="spinner-border spinner-border-sm" v-show="wakeupLoading"></span>目覚めた!
                </button>
                <span class="col-8 container" style="z-index:1" v-show="depositFlag && checkOverslept" data-bs-toggle="tooltip" title="起床時刻を再セットしてください">
                    <button class="btn btn-outline-secondary" style="width:100%;z-index:2" v-show="depositFlag && checkOverslept" disabled>あなたは寝坊しました</button>
                </span>
                <button class="col-8 btn btn-success" v-if="rewardFlag" @click="receiveReward()">
                    <span class="spinner-border spinner-border-sm" v-show="rewardLoading"></span>報酬を受け取る!
                </button>
            </div>
            <div class="row m-2 justify-content-center">
                <Datepicker class="col-6" v-model="dateInput" position="left" monthNameFormat="long" locale="jp" showNowButton nowButtonLabel="現在時刻" selectText="決定" cancelText="キャンセル" required>
                    <template #calendar-header="{ index, day }">
                        <div :class="index === 5 || index === 6 ? 'red-color' : ''">
                            {{ day }}
                        </div>
                    </template>
                </Datepicker>
                <button class="col-6 btn btn-secondary" v-show="!shouldWakeupTimeSet" data-bs-toggle="modal" data-bs-target="#setWakeupTimeModal">
                    <span class="spinner-border spinner-border-sm" v-show="setWakeupLoading"></span>起床時刻をリセット
                </button>
                <button class="col-6 btn btn-primary" v-show="shouldWakeupTimeSet" data-bs-toggle="modal" data-bs-target="#setWakeupTimeModal">
                    <span class="spinner-border spinner-border-sm" v-show="setWakeupLoading"></span>起床時刻をセット
                </button>
            </div>
            <div class="row m-2 justify-content-center">
                <div class="col">
                    <ul class="list-group">
                        <li class="list-group-item">起床予定時刻: {{ wakeupTimeToLocale }}</li>
                        <li class="list-group-item">起床報告期限: {{ wakeupTimeToToLocale }}</li>
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

const wakeupABI = JSON.parse(text).abi
const wakeupAddress = "0x461a1c9630162652d0e2378e65AdeDdf1EFA2342"

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
            rewardFlag: false,
            setWakeupLoading: false,
            wakeupLoading: false,
            rewardLoading: false,
            setWakeupTimeSuccessAlert: false,
            setWakeupTimeFailedAlert: false,
            wakeupSuccessAlert: false,
            wakeupFailedAlert: false,
            receiveRewardSuccessAlert: false,
            receiveRewardFailedAlert: false
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
        },
        shouldWakeupTimeSet() {
            return this.checkOverslept || (!this.depositFlag && !this.rewardFlag)
        },
        checkOverslept() {
            return this.wakeupTimeTo.getTime() < (new Date()).getTime()
        },
        checkStillSleep() {
            return this.wakeupTime.getTime() > (new Date()).getTime()
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
        }
    },
    methods:{
        async startApp() {
            if (metamask !== window.ethereum) {
                console.error('Do you have multiple wallets installed?')
            }
            web3 = new Web3(Web3.givenProvider || "ws://localhost:7545")
            wakeupContract = new web3.eth.Contract(wakeupABI, wakeupAddress)
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
            this.checkContractBalance()
            this.displayUserInfo(),
            this.checkOverslept
        },
        displayUserInfo(){
            this.retry(this.getUserInfo, 5)
            .then((userInfo)=>{
                this.wakeupTime = new Date(userInfo[0]*1000)
                this.wakeupTimeTo = new Date(userInfo[1]*1000)
                this.lastUpdated = new Date(userInfo[2]*1000)
                this.contDays = userInfo[3]
                this.depositFlag = userInfo[4]
                this.rewardFlag = userInfo[5]
                if(userInfo[0] != 0){
                    this.dateInput = new Date(this.wakeupTime)
                }
            })
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
            this.wakeupLoading = true
            wakeupContract.methods.incrementContDays()
            .send({ from: userAccount })
            .then((result)=>{
                this.wakeupSuccessAlert = true
                console.log(result)
            })
            .catch((error)=>{
                this.wakeupFailedAlert = true
                console.log(error)
            })
            .finally(()=>{
                this.wakeupLoading = false
                this.displayContDays()
            })
        },
        setWakeupTime() {
            this.setWakeupLoading = true
            wakeupContract.methods.setWakeupTime(this.dateToEpoch)
            .send({ from: userAccount, value: web3.utils.toWei("0.01", "ether")})
            .then((result)=>{
                this.setWakeupTimeSuccessAlert = true
                console.log(result)
            })
            .catch((error)=>{
                this.setWakeupTimeFailedAlert = true
                console.log(error)
            })
            .finally(()=>{
                this.displayContDays()
                this.setWakeupLoading = false
            })
        },
        receiveReward() {
            this.getRewardFlag()
            .then((rewardFlag)=>{
                if(!rewardFlag){
                    console.log("You have not gotten reward.")
                    return
                }
                this.rewardLoading = true
                wakeupContract.methods.receiveReward()
                .send({ from: userAccount })
                .then((result)=>{
                    this.receiveRewardSuccessAlert = true
                    console.log(result)
                })
                .catch((error)=>{
                    this.receiveRewardFailedAlert = true
                    console.log(error)
                })
                .finally(()=>{
                    this.displayContDays()
                    this.rewardLoading = false
                })
            })
        },
        getRewardFlag() {
            return wakeupContract.methods.getRewardFlag(userAccount).call()
        },
        getBalance() {
            return wakeupContract.methods.getBalance().call()
        },
        getUserInfo() {
            return wakeupContract.methods.getUserInfo(userAccount).call()
        },
        retry(func, retryCount) {
            let promise = func();
            for (let i = 0; i < retryCount; i++) {
                promise = promise.catch((err)=>{
                    console.log(err)
                    func()
                })
            }
            return promise;
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
  background-image: url("../assets/background.jpeg");
  background-size: 100% 100%;
  background-size: cover;
  position:fixed;
}
</style>