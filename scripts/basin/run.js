const hre = require("hardhat");

const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const contractFactory = await hre.ethers.getContractFactory('BasinDataStore');
    const contract = await contractFactory.deploy();
    await contract.deployed();

    let randAddress = randomPerson.address

    console.log("Contract deployed to:", contract.address);
    console.log("Contract deployed by:", owner.address);

    let createStandard = await contract.createStandard(
        "The_First_Standard",
        "{'id':'string'}"
    );
    await createStandard.wait();

    let standards = await contract.fetchAllStandards();
    console.log("standards:", standards);

    let storeData1 = await contract.storeData(owner.address, randAddress, 0, "{'id': '123456'}");
    await storeData1.wait();

    let providerData1 = await contract.fetchProviderData();
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