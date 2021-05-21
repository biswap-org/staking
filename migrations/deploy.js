async function main() {
    // We get the contract to deploy
    const MasterChef = await ethers.getContractFactory('MasterChef');
    console.log('Deploying MasterChef...');
 
    // Instantiating a new Box smart contract
    const box = await MasterChef.deploy(
        "0x6b5c8ed60f10946662565e76e421c5fa7330260e",
        "0xdBE55A0daDc80EF88e884f15CE41c26c0Af933a0",
        "0xdBE55A0daDc80EF88e884f15CE41c26c0Af933a0",
        "30000000000000000000",
        "8626338",
        "8626338",
        '875000',
        '100000',
        '43000'
    );
 
    // Waiting for the deployment to resolve
    await box.deployed();
    console.log('Box deployed to:', box.address);
 }
 
 main()
    .then(() => process.exit(0))
    .catch((error) => {
       console.error(error);
       process.exit(1);
    });