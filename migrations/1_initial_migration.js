const TokenA = artifacts.require("CakeToken");
const TokenB = artifacts.require("CakeToken2");
const WBNB = artifacts.require("WBNB");
const MastefChef = artifacts.require('MasterChef');

const Uni = artifacts.require("Uni");
const Uni2 = artifacts.require("Uni2");

const { MaxUint256 } = require("@ethersproject/constants");
const { BigNumber }  = require('@ethersproject/bignumber');
const JSBI           = require('jsbi')
module.exports = async function(deployer) {
  let address = deployer.networks.development.from;


  await deployer.deploy(MastefChef);

  const instanceMasterChef = await MastefChef.deployed();
  console.log(instanceMasterChef);

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