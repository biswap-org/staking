pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import '@biswap/biswap-core-libs/contracts/math/SafeMath.sol';
import '@biswap/biswap-core-libs/contracts/token/BEP20/IBEP20.sol';
import '@biswap/biswap-core-libs/contracts/token/BEP20/SafeBEP20.sol';
import '@biswap/biswap-core-libs/contracts/access/Ownable.sol';

import "./BSWToken.sol";
import "@nomiclabs/buidler/console.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to BSWSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // BSWSwap must mint EXACTLY the same amount of BSWSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IBEP20 token) external returns (IBEP20);
}

// MasterChef is the master of BSW. He can make BSW and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BSW is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BSWs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBSWPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBSWPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. BSWs to distribute per block.
        uint256 lastRewardBlock; // Last block number that BSWs distribution occurs.
        uint256 accBSWPerShare; // Accumulated BSWs per share, times 1e12. See below.
    }
    // The BSW TOKEN!
    BSWToken public BSW;
    //Pools, Farms, Dev, Refs percent decimals
    uint256 public percentDec = 1000000;
    //Pools and Farms percent from token per block
    uint256 public stakingPercent;
    //Developers percent from token per block
    uint256 public devPercent;
    //Referrals percent from token per block
    uint256 public refPercent;
    // Dev address.
    address public devaddr;
    // Refferals commision address.
    address public refAddr;
    // Last block then develeper withdraw dev and ref fee
    uint256 public lastBlockDevWithdraw;
    // Block number when bonus BSW period ends.
    uint256 public bonusEndBlock;
    // BSW tokens created per block.
    uint256 public BSWPerBlock;
    // Bonus muliplier for early BSW makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BSW mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event StakingPercentChanged(uint256 currentPercent);
    event DevPercentChanged(uint256 currentPercent);
    event RefPercentChanged(uint256 currentPercent);

    constructor(
        BSWToken _BSW,
        address _devaddr,
        address _refAddr,
        uint256 _BSWPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _stakingPercent,
        uint256 _devPercent,
        uint256 _refPercent
    ) public {
        BSW = _BSW;
        devaddr = _devaddr;
        refAddr = _refAddr;
        BSWPerBlock = _BSWPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        stakingPercent = _stakingPercent;
        devPercent = _devPercent;
        refPercent = _refPercent;
        lastBlockDevWithdraw = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function setStakingPercent(uint256 percent) public onlyOwner{
        require(percent < 1000000, 'more then 100%');
        require(percent >= 400000, 'lower then 40%');
        stakingPercent = percent;
        emit StakingPercentChanged(stakingPercent);
    }
    function setDevPercent(uint256 percent) public onlyOwner{
        require(percent <= 300000, 'more then 30%');
        require(percent >= 20000, 'lower then 2%');
        devPercent = percent;
        emit DevPercentChanged(devPercent);
    }
    function setRefPercent(uint256 percent) public onlyOwner{
        require(percent <= 500000, 'more then 50%');
        require(percent >= 50000, 'lower then 5%');
        refPercent = percent;
        emit RefPercentChanged(refPercent);
    }

    function withdrawDevAndRefFee() public onlyOwner{
        require(lastBlockDevWithdraw < block.number, 'wait for new block');
        uint256 multiplier = getMultiplier(lastBlockDevWithdraw, block.number);
        uint256 BSWReward = multiplier.mul(BSWPerBlock);
        BSW.mint(devaddr, BSWReward.mul(devPercent).div(percentDec));
        BSW.mint(refAddr, BSWReward.mul(refPercent).div(percentDec));
        lastBlockDevWithdraw = block.number;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add( uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBSWPerShare: 0
            })
        );
    }

    // Update the given pool's BSW allocation point. Can only be called by the owner.
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
        }
    }

    // View function to see pending BSWs on frontend.
    function pendingBSW(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBSWPerShare = pool.accBSWPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 BSWReward = multiplier.mul(BSWPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(stakingPercent).div(percentDec);
            accBSWPerShare = accBSWPerShare.add(BSWReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBSWPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
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
        console.log('pool.lastRewardBlock, block.number - ', pool.lastRewardBlock, block.number);
        uint256 BSWReward = multiplier.mul(BSWPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(stakingPercent).div(percentDec);
        console.log('REWARD - ', BSWReward);
        console.log('multiplier - ', multiplier);
        console.log('pool.allocPoint - ', pool.allocPoint);
        console.log('totalAllocPoint - ', totalAllocPoint);
        BSW.mint(address(this), BSWReward);
        pool.accBSWPerShare = pool.accBSWPerShare.add(BSWReward.mul(1e12).div(lpSupply));
        console.log('pool.accBSWPerShare - ', pool.accBSWPerShare.div(1e12));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BSW allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBSWPerShare).div(1e12).sub(user.rewardDebt);
            safeBSWTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accBSWPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBSWPerShare).div(1e12).sub(user.rewardDebt);
        safeBSWTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accBSWPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe BSW transfer function, just in case if rounding error causes pool to not have enough BSWs.
    function safeBSWTransfer(address _to, uint256 _amount) internal {
        uint256 BSWBal = BSW.balanceOf(address(this));
        if (_amount > BSWBal) {
            BSW.transfer(_to, BSWBal);
        } else {
            BSW.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}