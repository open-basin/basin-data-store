const hre = require("hardhat");
const { utils } = require("./utils/utils.js");

const main = async () => {
    const dataStoreContract = await hre.ethers.getContractAt('DataStore',process.env.CURRENT_CONTRACT);

    var standards = [];

    console.log("----------------------- Create Standard");

    // let createStandard = await dataStoreContract.storeStandard("One", "{}", { gasLimit: 3500000 });
    // await createStandard.wait();

    standards = await dataStoreContract.allStandards();
    console.log("standards:", utils.structureStandards(standards));
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

runMain();