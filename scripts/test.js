const hre = require("hardhat");
const { utils } = require("./utils/utils.js");

const main = async () => {
    const dataStoreContract = await hre.ethers.getContractAt('DataStore', process.env.CURRENT_CONTRACT);
    const signer = process.env.PUBLIC_KEY;

    var standards = [];
    var data = [];

    console.log("----------------------- Standards");

    // let createStandard = await dataStoreContract.storeStandard("Two", "{Nick", { gasLimit: 3500000 });
    // await createStandard.wait();
    // console.log("Created Standard");

    standards = await dataStoreContract.allStandards();
    console.log("standards:", utils.structureStandards(standards));

    console.log("----------------------- Data");

    // let createData = await dataStoreContract.storeData(signer, 0, "{}", { gasLimit: 3500000 });
    // await createData.wait();
    // console.log("Created Data");

    data = await dataStoreContract.dataForOwner(signer);
    console.log("data:", utils.structureData(data));
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