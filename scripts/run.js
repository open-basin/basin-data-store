const hre = require("hardhat");

const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const basinDataStoreFactory = await hre.ethers.getContractFactory('BasinDataStore');
    const basinDataStoreContract = await basinDataStoreFactory.deploy();
    await basinDataStoreContract.deployed();

    let randAddress = randomPerson.address

    console.log("Contract deployed to:", basinDataStoreContract.address);
    console.log("Contract deployed by:", owner.address);
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();