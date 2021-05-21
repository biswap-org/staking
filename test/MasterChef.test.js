const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const JSBI           = require('jsbi')
const CakeToken = artifacts.require('BSWToken');
const MasterChef = artifacts.require('MasterChef');
const MockBEP20 = artifacts.require('libs/MockBEP20');
let perBlock = '30000000000000000000';
const delay = ms => new Promise(res => setTimeout(res, ms));
contract('MasterChef', ([alice, bob, carol, dev, refFeeAddr, minter]) => {
    beforeEach(async () => {
        this.cake = await CakeToken.new({ from: minter });
    
        this.lp1 = await MockBEP20.new('LPToken', 'LP1', '1000000', { from: minter });
        this.lp2 = await MockBEP20.new('LPToken', 'LP2', '1000000', { from: minter });
        this.lp3 = await MockBEP20.new('LPToken', 'LP3', '1000000', { from: minter });
        this.lp4 = await MockBEP20.new('LPToken', 'LP4', '1000000', { from: minter });
        
        
        await this.cake.addMinter(minter, { from: minter });
        this.chef = await MasterChef.new(this.cake.address, dev, refFeeAddr, perBlock, '206', '1000', '857000', '100000', '43000', { from: minter });
        await this.cake.addMinter(this.chef.address, { from: minter });
        await this.cake.mint(alice, "1", { from: minter });
        //await this.cake.transferOwnership(this.chef.address, { from: minter });
        
    

        await this.lp1.transfer(bob, '2000', { from: minter });
        await this.lp1.transfer(carol, '2000', { from: minter });
        await this.lp2.transfer(bob, '2000', { from: minter });
        await this.lp2.transfer(carol, '2000', { from: minter });
       // await this.lp3.transfer(bob, '2000', { from: minter });

        await this.lp1.transfer(alice, '2000', { from: minter });
        await this.lp2.transfer(alice, '2000', { from: minter });
        await this.lp3.transfer(alice, '2000', { from: minter });
        //await this.lp4.transfer(alice, '2000', { from: minter });

        
      
    });
    it('real case', async () => {

        await this.chef.add('1000', this.lp1.address, true, { from: minter });
        console.log('pools count', (await this.chef.poolLength()).toString());

        await time.advanceBlockTo('200');
        //1 - lp
        await this.lp1.approve(this.chef.address, '1000', { from: alice });
        await this.cake.approve(this.chef.address, '1000', { from: alice });
        // await this.lp1.approve(this.chef.address, '1000', { from: bob });
        // await this.lp1.approve(this.chef.address, '1000', { from: carol });
        console.log('----Deposit----');
        await this.chef.deposit(1, '1', { from: alice });
        await this.chef.enterStaking('1', { from: alice });
        // await this.chef.deposit(1, '1', { from: bob });
        // await this.chef.deposit(1, '1', { from: carol });
        console.log('---------------');
        console.log((await time.latestBlock()).toString());
        await time.advanceBlockTo('206');
        
        console.log('---Withdraw---');
        await this.chef.withdraw(1, '1', { from: alice });
        let aliceBalance = await this.cake.balanceOf(alice);
        console.log('alise balance: ', aliceBalance.toString());

        await this.chef.leaveStaking('1', { from: alice });
        aliceBalance = await this.cake.balanceOf(alice);
        console.log('alise balance: ', aliceBalance.toString());

        console.log('---------------');
        console.log((await time.latestBlock()).toString());

        // await this.chef.withdraw(1, '1', { from: bob });
        // let bobBalance = await this.cake.balanceOf(bob);
        // console.log('bob balance: ', bobBalance.toString());

        // await this.chef.withdraw(1, '1', { from: carol });
        // let carolBalance = await this.cake.balanceOf(carol);
        // console.log('carol balance: ', carolBalance.toString());
        // console.log('--------------');

        // let allUserBalance = JSBI.add(JSBI.BigInt(aliceBalance), JSBI.BigInt(carolBalance));
        // allUserBalance = JSBI.add(allUserBalance, JSBI.BigInt(bobBalance));
        // console.log('all user balance: ', allUserBalance.toString());


        
        await this.chef.withdrawDevAndRefFee({ from: minter });
        let balanceDev = await this.cake.balanceOf(dev);
        console.log('dev address balance: ', balanceDev.toString());
        let balanceRef = await this.cake.balanceOf(refFeeAddr);
        console.log('ref address balance: ', balanceRef.toString());

        
        



        // let alicePending = (await this.chef.pendingSushi(0, alice, { from: alice })).toString();
        // console.log('alise pending: ', alicePending);
        // //assert.equal(alicePending, '33');
        // console.log('----');
        // let bobPending = (await this.chef.pendingSushi(0, bob, { from: bob })).toString();
        // console.log('bob pending: ', bobPending);
        // //assert.equal(bobPending, '33');
        // console.log('----');
        // let carolPending = (await this.chef.pendingSushi(0, carol, { from: carol })).toString();
        // console.log('carol pending: ', carolPending);
        // //assert.equal(carolPending, '33');
        // console.log('----');
        // //3 - lp
        // await this.lp3.approve(this.chef.address, '1000', { from: alice });
        // await this.chef.deposit(2, '1', { from: alice });
        // await this.chef.withdraw(2, '1', { from: alice });


        // console.log('---Dev fee---');
        // await this.chef.devFeeWithdrawal({from: minter});
        // console.log('--------------');
        // console.log('---Local dev fee info---');
        // let balanceDev = await this.cake.balanceOf(dev);
        // let balanceRef = await this.cake.balanceOf(refFeeAddr);
        // let aliceBalance = await this.cake.balanceOf(alice);
        // console.log('dev', balanceDev.toString());
        // console.log('ref', balanceRef.toString());
        // // assert.equal((await this.cake.balanceOf(dev)).toString(), '12');
        // // assert.equal((await this.cake.balanceOf(refFeeAddr)).toString(), '6');
        // // assert.equal((await this.cake.balanceOf(alice)).toString(), '26');

        // console.log(perBlock);
        // let devAddRef = JSBI.add(JSBI.BigInt(balanceRef), JSBI.BigInt(balanceDev));
        // let allBalance = JSBI.add(JSBI.BigInt(aliceBalance), devAddRef);
        // console.log(allBalance.toString());
        // console.log(JSBI.subtract(JSBI.BigInt(perBlock), allBalance).toString());
        // console.log('--------------');
            
       

        // await this.cake.approve(this.chef.address, '1000', { from: alice });
        // await this.chef.enterStaking('20', { from: alice });
        // await this.chef.enterStaking('0', { from: alice });
        // await this.chef.enterStaking('0', { from: alice });
        // await this.chef.enterStaking('0', { from: alice });
        // assert.equal((await this.cake.balanceOf(alice)).toString(), '993');
        // // assert.equal((await this.chef.getPoolPoint(0, { from: minter })).toString(), '1900');
    })


    // it('deposit/withdraw', async () => {
    //     await this.chef.add('1000', this.lp1.address, true, { from: minter });
    //     await this.chef.add('1000', this.lp2.address, true, { from: minter });
    //     await this.chef.add('1000', this.lp3.address, true, { from: minter });
    //
    //     await this.lp1.approve(this.chef.address, '100', { from: alice });
    //     await this.chef.deposit(1, '20', { from: alice });
    //     await this.chef.deposit(1, '0', { from: alice });
    //     await this.chef.deposit(1, '40', { from: alice });
    //     await this.chef.deposit(1, '0', { from: alice });
    //     assert.equal((await this.lp1.balanceOf(alice)).toString(), '1940');
    //     await this.chef.withdraw(1, '10', { from: alice });
    //     assert.equal((await this.lp1.balanceOf(alice)).toString(), '1950');
    //     assert.equal((await this.cake.balanceOf(alice)).toString(), '999');
    //     assert.equal((await this.cake.balanceOf(dev)).toString(), '100');
    //
    //     await this.lp1.approve(this.chef.address, '100', { from: bob });
    //     assert.equal((await this.lp1.balanceOf(bob)).toString(), '2000');
    //     await this.chef.deposit(1, '50', { from: bob });
    //     assert.equal((await this.lp1.balanceOf(bob)).toString(), '1950');
    //     await this.chef.deposit(1, '0', { from: bob });
    //     assert.equal((await this.cake.balanceOf(bob)).toString(), '125');
    //     await this.chef.emergencyWithdraw(1, { from: bob });
    //     assert.equal((await this.lp1.balanceOf(bob)).toString(), '2000');
    // })
    //
    // it('staking/unstaking', async () => {
    //     await this.chef.add('1000', this.lp1.address, true, { from: minter });
    //     await this.chef.add('1000', this.lp2.address, true, { from: minter });
    //     await this.chef.add('1000', this.lp3.address, true, { from: minter });
    //
    //     await this.lp1.approve(this.chef.address, '10', { from: alice });
    //     await this.chef.deposit(1, '2', { from: alice }); //0
    //     await this.chef.withdraw(1, '2', { from: alice }); //1
    //
    //     await this.cake.approve(this.chef.address, '250', { from: alice });
    //     await this.chef.enterStaking('240', { from: alice }); //3
    //     assert.equal((await this.syrup.balanceOf(alice)).toString(), '240');
    //     assert.equal((await this.cake.balanceOf(alice)).toString(), '10');
    //     await this.chef.enterStaking('10', { from: alice }); //4
    //     assert.equal((await this.syrup.balanceOf(alice)).toString(), '250');
    //     assert.equal((await this.cake.balanceOf(alice)).toString(), '249');
    //     await this.chef.leaveStaking(250);
    //     assert.equal((await this.syrup.balanceOf(alice)).toString(), '0');
    //     assert.equal((await this.cake.balanceOf(alice)).toString(), '749');
    //
    // });
    //
    //
    // it('update multiplier', async () => {
    //     await this.chef.add('1000', this.lp1.address, true, { from: minter });
    //     await this.chef.add('1000', this.lp2.address, true, { from: minter });
    //     await this.chef.add('1000', this.lp3.address, true, { from: minter });
    //
    //     await this.lp1.approve(this.chef.address, '100', { from: alice });
    //     await this.lp1.approve(this.chef.address, '100', { from: bob });
    //     await this.chef.deposit(1, '100', { from: alice });
    //     await this.chef.deposit(1, '100', { from: bob });
    //     await this.chef.deposit(1, '0', { from: alice });
    //     await this.chef.deposit(1, '0', { from: bob });
    //
    //     await this.cake.approve(this.chef.address, '100', { from: alice });
    //     await this.cake.approve(this.chef.address, '100', { from: bob });
    //     await this.chef.enterStaking('50', { from: alice });
    //     await this.chef.enterStaking('100', { from: bob });
    //
    //     await this.chef.updateMultiplier('0', { from: minter });
    //
    //     await this.chef.enterStaking('0', { from: alice });
    //     await this.chef.enterStaking('0', { from: bob });
    //     await this.chef.deposit(1, '0', { from: alice });
    //     await this.chef.deposit(1, '0', { from: bob });
    //
    //     assert.equal((await this.cake.balanceOf(alice)).toString(), '700');
    //     assert.equal((await this.cake.balanceOf(bob)).toString(), '150');
    //
    //     await time.advanceBlockTo('265');
    //
    //     await this.chef.enterStaking('0', { from: alice });
    //     await this.chef.enterStaking('0', { from: bob });
    //     await this.chef.deposit(1, '0', { from: alice });
    //     await this.chef.deposit(1, '0', { from: bob });
    //
    //     assert.equal((await this.cake.balanceOf(alice)).toString(), '700');
    //     assert.equal((await this.cake.balanceOf(bob)).toString(), '150');
    //
    //     await this.chef.leaveStaking('50', { from: alice });
    //     await this.chef.leaveStaking('100', { from: bob });
    //     await this.chef.withdraw(1, '100', { from: alice });
    //     await this.chef.withdraw(1, '100', { from: bob });
    //
    // });
    //
    // it('should allow dev and only dev to update dev', async () => {
    //     assert.equal((await this.chef.devaddr()).valueOf(), dev);
    //     await expectRevert(this.chef.dev(bob, { from: bob }), 'dev: wut?');
    //     await this.chef.dev(bob, { from: dev });
    //     assert.equal((await this.chef.devaddr()).valueOf(), bob);
    //     await this.chef.dev(alice, { from: bob });
    //     assert.equal((await this.chef.devaddr()).valueOf(), alice);
    // })
});
