pragma solidity 0.6.12;

import '@biswap/biswap-core-libs/contracts/math/SafeMath.sol';
import '@biswap/biswap-core-libs/contracts/token/BEP20/IBEP20.sol';
import '@biswap/biswap-core-libs/contracts/token/BEP20/SafeBEP20.sol';
import '@biswap/biswap-core-libs/contracts/access/Ownable.sol';

import "@nomiclabs/buidler/console.sol";

contract SmartChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BSWs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BSWs distribution occurs.
        uint256 accBSWPerShare; // Accumulated BSWs per share, times 1e12. See below.
    }

    // The BSW TOKEN!
    IBEP20 public biswap;
    IBEP20 public rewardToken;

    // BSW tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    //Pools, Farms, Dev, Refs percent decimals
    uint256 public percentDec = 1000000;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BSW mining starts.
    uint256 public startBlock;
    // The block number when BSW mining ends.
    uint256 public bonusEndBlock;

    //Referrals percent from token per block
    uint256 public refPercent;
    // Refferals commision address.
    address public refAddr;
    // Last block then develeper withdraw dev and ref fee
    uint256 public lastBlockDevWithdraw;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RefPercentChanged(uint256 currentPercent);

    constructor(
        IBEP20 _bsw,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _refPercent,
        address _refFeeAddr
    ) public {
        biswap = _bsw;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        refPercent = _refPercent;
        refAddr = _refFeeAddr;
        lastBlockDevWithdraw = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _bsw,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accBSWPerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function setRefPercent(uint256 percent) public onlyOwner{
        require(percent <= 500000, 'more then 50%');
        require(percent >= 50000, 'lower then 5%');
        refPercent = percent;
        emit RefPercentChanged(refPercent);
    }

    function withdrawRefFee() public onlyOwner{
        require(lastBlockDevWithdraw < block.number, 'wait for new block');
        uint256 multiplier = getMultiplier(lastBlockDevWithdraw, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        rewardToken.safeTransfer(refAddr, reward.mul(refPercent).div(percentDec));
        lastBlockDevWithdraw = block.number;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accBSWPerShare = pool.accBSWPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 BSWReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBSWPerShare = accBSWPerShare.add(BSWReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBSWPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 BSWReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accBSWPerShare = pool.accBSWPerShare.add(BSWReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake biswap tokens to SmartChef
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBSWPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBSWPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw biswap tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accBSWPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            console.log(pending);
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBSWPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

}