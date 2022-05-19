const hre = require("hardhat");
const { utils } = require("./utils/utils.js");

const main = async () => {
    const dataStoreContract = await hre.ethers.getContractAt('DataStore', process.env.CURRENT_CONTRACT);
    const signer = process.env.PUBLIC_KEY;

    var standards = [];
    var data = [];

    console.log("----------------------- Standards");

    // let createStandard = await dataStoreContract.storeStandard("Coordinate 2", `{
    //     "id": "http://json-schema.org/geo",
    //     "$schema": "http://json-schema.org/draft-06/schema#",
    //     "description": "A geographical coordinate",
    //     "type": "object",
    //     "properties": {
    //       "latitude": {
    //         "type": "number"
    //       },
    //       "longitude": {
    //         "type": "number"
    //       }
    //     }
    //   }`, { gasLimit: 3500000 });
    // const standardToken = await createStandard.wait();
    // console.log("Created Standard:" + standardToken);

    // let createStandard = await dataStoreContract.storeStandard("Zero 2", `{}`, { gasLimit: 3500000 });
    // const standardToken = await createStandard.wait();
    // console.log("Created Standard:" + standardToken);

    // standards = await dataStoreContract.allStandards();
    // console.log("standards:", utils.structureStandards(standards));

    const standard = await dataStoreContract.standardForToken(5);
    console.log("standard 5:", utils.structureStandard(standard));

    console.log("----------------------- Data");

    // let createData = await dataStoreContract.storeData(signer, 5, `{
    //     "latitude": 42.0501,
    //     "longitude": 72.5829
    // }`, { gasLimit: 3500000 });
    // const dataToken = await createData.wait();
    // console.log("Created Data" + dataToken);

    // let createData = await dataStoreContract.storeData(signer, 6, `{}`, { gasLimit: 3500000 });
    // const dataToken = await createData.wait();
    // console.log("Created Data" + dataToken);

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