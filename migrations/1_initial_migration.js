// const TokenA = artifacts.require("CakeToken");
// const TokenB = artifacts.require("CakeToken2");
// const WBNB = artifacts.require("WBNB");
const MastefChef = artifacts.require('MasterChef');

// const Uni = artifacts.require("Uni");
// const Uni2 = artifacts.require("Uni2");

// const { MaxUint256 } = require("@ethersproject/constants");
// const { BigNumber }  = require('@ethersproject/bignumber');
// const JSBI           = require('jsbi')
module.exports = async function(deployer) {
  let address = deployer.networks.development.from;


  await deployer.deploy(MastefChef, 
    "0x6b5c8ed60f10946662565e76e421c5fa7330260e",
    "0xdBE55A0daDc80EF88e884f15CE41c26c0Af933a0",
    "0xdBE55A0daDc80EF88e884f15CE41c26c0Af933a0",
    "30000000000000000000",
    "8626338",
    "8626338",
    '857000',
    '100000',
    '43000'
);

  const instanceMasterChef = await MastefChef.deployed();

  //console.log(await instanceMasterChef.add(1000, '', true));

  // await deployer.deploy(TokenA);
  // await deployer.deploy(TokenB);
  // await deployer.deploy(WBNB);

  // await deployer.deploy(Uni, address, address, JSBI.BigInt(1000000000000000000).toString(10));
  // await deployer.deploy(Uni2, address, address, JSBI.BigInt(1000000000000000000).toString(10));

  // const TokenAInstance = await TokenA.deployed();
  // const TokenBInstance = await TokenB.deployed();
  // const WBNBInstance = await WBNB.deployed();
  // const UniInstance = await Uni.deployed();
  // const Uni2Instance = await Uni2.deployed();
  //
  // await TokenAInstance.mint(address, JSBI.BigInt(100000000000000000000).toString(10));
  // await TokenBInstance.mint(address, JSBI.BigInt(100000000000000000000).toString(10));
  //
  // let balanceTokenA = await TokenAInstance.balanceOf(address);
  // let balanceTokenB = await TokenBInstance.balanceOf(address);
  // let balanceUni = await UniInstance.balanceOf(address);
  // let balanceUni2 = await Uni2Instance.balanceOf(address);
  //
  // console.log('Balance token A: ', normalDecimal(balanceTokenA));
  // console.log('Balance token B: ', normalDecimal(balanceTokenB));
  // console.log('Balance token Uni: ',normalDecimal(balanceUni));
  // console.log('Balance token Uni2: ', normalDecimal(balanceUni2));

};


function toDecimal(a){
  return a * 1000000000000000000;
}
function normalDecimal(a){
  if (a === 0) return 0;
  return a / 1000000000000000000;
}