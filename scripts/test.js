const hre = require("hardhat");
const { utils } = require("./utils/utils.js");

const main = async () => {
    const dataStoreContract = await hre.ethers.getContractAt('DataStore', process.env.CURRENT_CONTRACT);
    const signer = process.env.PUBLIC_KEY;

    // let setBank = await dataStoreContract.changeFees(hre.ethers.utils.parseEther("0.00002"), hre.ethers.utils.parseEther("0.00001"), hre.ethers.utils.parseEther("0.00001"));
    // await setBank.wait();

    // console.log("Set up Bank");

    var standards = [];
    var data = [];

    console.log("----------------------- Standards");

    // let createStandard = await dataStoreContract.createStandard("Coordinate 2", `{
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
    //   }`, { gasLimit: 3500000, value: 200 });
    // const standardToken = await createStandard.wait();
    // console.log("Created Standard:" + standardToken);

    // let createStandard = await dataStoreContract.createStandard("Zero", `{}`, { gasLimit: 3500000, value: hre.ethers.utils.parseEther("0.00002") } );
    // const standardToken = await createStandard.wait();
    // console.log("Created Standard:" + standardToken);

    // const standard = await dataStoreContract.standardForToken(5);
    // console.log("standard 5:", utils.structureStandard(standard));

    standards = await dataStoreContract.allStandards();
    console.log("standards:", utils.structureStandards(standards));

    console.log("----------------------- Data");

    // let createData = await dataStoreContract.storeData(signer, 5, `{
    //     "latitude": 42.0501,
    //     "longitude": 72.5829
    // }`, { gasLimit: 3500000 });
    // const dataToken = await createData.wait();
    // console.log("Created Data" + dataToken);

    // let createData = await dataStoreContract.storeData(signer, 1, `{}`, { gasLimit: 3500000, value: hre.ethers.utils.parseEther("0.0001") } );
    // const dataToken = await createData.wait();
    // console.log("Created Data" + dataToken);

    data = await dataStoreContract.dataForOwner(signer);
    console.log("data:", utils.structureData(data));

    // data = await dataStoreContract.dataForOwnerInStandard(signer, 1);
    // console.log("data:", utils.structureData(data));
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