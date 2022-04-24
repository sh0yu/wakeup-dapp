// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Wakeup {
    uint private constant DEPOSIT = 0.01 ether;
    uint private constant REWARD = 0.003 ether;
    uint private constant CONT_DAYS_MAX = 5;
    uint private constant INVALID_WAKUP_TIME = 15 minutes;
    uint private constant NEXT_INVALID_TIME = 1 days;
    address private owner;

    constructor () {
        owner = msg.sender;
    }

    struct User {
        uint wakeupTime;
        uint wakeupTimeTo;
        uint lastUpdated;
        uint contDays;
        bool depositFlag;
        bool rewardFlag;
    }

    mapping (address => User) user;

    function setWakeupTime(uint _wakeupTime) public payable {
        require(user[msg.sender].rewardFlag == false, "You must receive reward first");
        require(msg.value == DEPOSIT, "Initial Deposit invalid error");
        user[msg.sender] = User({
            lastUpdated: block.timestamp,
            wakeupTime: _wakeupTime,
            wakeupTimeTo: _wakeupTime + INVALID_WAKUP_TIME,
            contDays: 0,
            depositFlag: true,
            rewardFlag: false
        });
    }

    function incrementContDays() public {
        require(user[msg.sender].depositFlag, "You have to deposit first");
        require(user[msg.sender].wakeupTime <= block.timestamp, "You can still sleep");
        require(user[msg.sender].wakeupTimeTo >= block.timestamp, "You overslept... restart routine");
        user[msg.sender].lastUpdated = block.timestamp;
        if (user[msg.sender].contDays == (CONT_DAYS_MAX-1)) {
            user[msg.sender].wakeupTime = 0;
            user[msg.sender].wakeupTimeTo = 0;
            user[msg.sender].depositFlag = false;
            user[msg.sender].rewardFlag = true;
            user[msg.sender].contDays = 0;
        } else {
            user[msg.sender].wakeupTime = user[msg.sender].wakeupTime + NEXT_INVALID_TIME;
            user[msg.sender].wakeupTimeTo = user[msg.sender].wakeupTimeTo + NEXT_INVALID_TIME;
            user[msg.sender].contDays++;
        }
    }

    function receiveReward() public {
        require(user[msg.sender].rewardFlag, "You have to keep waking up for 5days");
        user[msg.sender].rewardFlag = false;
        (bool success,) = payable(msg.sender).call{value: DEPOSIT + REWARD}("");
        require(success, "We couldn't pay reward");
    }

    function withdraw() external {
        require(msg.sender == owner, "You can't withdraw deposit");
        require(block.timestamp >= 1672531200, "You can't withdraw before 2023/1/1");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserInfo (address _user) public view returns (uint, uint, uint, uint, bool, bool) {
        return (user[_user].wakeupTime, user[_user].wakeupTimeTo, user[_user].lastUpdated, user[_user].contDays, user[_user].depositFlag, user[_user].rewardFlag);
    }

    function getWakeupTime(address _owner) public view returns (uint) {
        return user[_owner].wakeupTime;
    }

    function getWakeupTimeTo(address _owner) public view returns (uint) {
        return user[_owner].wakeupTimeTo;
    }

    function getLastUpdated(address _owner) public view returns (uint) {
        return user[_owner].lastUpdated;
    }
    
    function getContDays(address _owner) public view returns (uint) {
        return user[_owner].contDays;
    }

    function getDepositFlag(address _owner) public view returns (bool) {
        return user[_owner].depositFlag;
    }

    function getRewardFlag(address _owner) public view returns (bool) {
        return user[_owner].rewardFlag;
    }
}