const hre = require("hardhat");

const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const contractFactory = await hre.ethers.getContractFactory('DataStore');
    const contract = await contractFactory.deploy();
    await contract.deployed();

    console.log("Contract deployed to:", contract.address);
    console.log("Contract deployed by:", owner.address);

    let createStandard = await contract.createStandard(
        "The_First_Standard",
        "{'id':'string'}"
    );
    await createStandard.wait();

    let standards = await contract.allStandards();
    console.log("standards:", standards);

    let storeData1 = await contract.storeData(owner.address, 0, "{'id': '123456'}");
    await storeData1.wait();

    let ownerData1 = await contract.dataForOwner(owner.address);
    console.log("Owner Data 1:", ownerData1);

    let randData1 = await contract.dataForOwner(randomPerson.address);
    console.log("Random Data 1:", randData1);

    let transfer = await contract.transferData(0, randomPerson.address);
    await transfer.wait();

    let ownerData2 = await contract.dataForOwner(owner.address);
    console.log("Owner Data 2:", ownerData2);

    let randData2 = await contract.dataForOwner(randomPerson.address);
    console.log("Random Data 2:", randData2);
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