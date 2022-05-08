const hre = require("hardhat");

const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const contractFactory = await hre.ethers.getContractFactory('StandardValidation');
    const contract = await contractFactory.deploy();
    await contract.deployed();

    console.log("Contract deployed to:", contract.address);
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