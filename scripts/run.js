const hre = require("hardhat");

const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const basinDataStoreFactory = await hre.ethers.getContractFactory('BasinDataStore');
    const basinDataStoreContract = await basinDataStoreFactory.deploy();
    await basinDataStoreContract.deployed();

    let randAddress = randomPerson.address

    console.log("Contract deployed to:", basinDataStoreContract.address);
    console.log("Contract deployed by:", owner.address);

    let createStandard = await basinDataStoreContract.createStandard(
        "The First Standard",
        "{'id':string}"
    );
    await createStandard.wait();

    let standards = await basinDataStoreContract.fetchAllStandards();
    console.log("standards:", standards);

    let storeData1 = await basinDataStoreContract.storeData(owner.address, randAddress, 0, "{'id': '123456'}");
    await storeData1.wait();

    let providerData1 = await basinDataStoreContract.fetchProviderData();
    console.log("Provider Data 1:", providerData1);
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