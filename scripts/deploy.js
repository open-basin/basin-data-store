const hre = require("hardhat");
const { utils } = require("./utils/utils.js");
const { constants } = require("./utils/constants.js");

const main = async () => {
    const network = process.env.NETWORK;
    const owner = process.env.PUBLIC_KEY;

    var chainAddress = "";
    var oracleAddress = "";
    var jobId = "";
    var fee = 0;
    var standardEndpoint = "";
    var dataEndpoint = "";

    switch (network) {
        case 'RINKEBY':
            chainAddress = constants.rinkeby.chainAddress;
            oracleAddress = constants.rinkeby.oracleAddress;
            jobId = constants.rinkeby.jobId;
            fee = constants.rinkeby.fee;
            standardEndpoint = constants.rinkeby.standardEndpoint;
            dataEndpoint = constants.rinkeby.dataEndpoint;
            break;
        case 'KOVAN':
            chainAddress = constants.kovan.chainAddress;
            oracleAddress = constants.kovan.oracleAddress;
            jobId = constants.kovan.jobId;
            fee = constants.kovan.fee;
            standardEndpoint = constants.kovan.standardEndpoint;
            dataEndpoint = constants.kovan.dataEndpoint;
            break;
        default:
            break;
    }

    console.log("Deploying to", network);
    console.log("Deploying contracts with", owner);

    const standardStorageContractFactory = await hre.ethers.getContractFactory('StandardStorage');
    const standardStorageContract = await standardStorageContractFactory.deploy(
        owner,
        owner,
        owner,
        owner,
        { value: hre.ethers.utils.parseEther("0.001") }
    );
    await standardStorageContract.deployed();
    console.log("Standard Storage contract deployed to:", standardStorageContract.address);

    const dataStorageContractFactory = await hre.ethers.getContractFactory('DataStorage');
    const dataStorageContract = await dataStorageContractFactory.deploy(
        owner,
        owner,
        standardStorageContract.address,
        { value: hre.ethers.utils.parseEther("0.001") }
    );
    await dataStorageContract.deployed();
    console.log("Data Storage contract deployed to:", dataStorageContract.address);

    const standardValidationContractFactory = await hre.ethers.getContractFactory('StandardValidation');
    const standardValidationContract = await standardValidationContractFactory.deploy(
        owner,
        standardStorageContract.address,
        chainAddress,
        oracleAddress,
        jobId,
        fee,
        standardEndpoint,
        { value: hre.ethers.utils.parseEther("0.001") }
    );
    await standardValidationContract.deployed();
    console.log("Standard Validation contract deployed to:", standardValidationContract.address);

    const dataValidationContractFactory = await hre.ethers.getContractFactory('DataValidation');
    const dataValidationContract = await dataValidationContractFactory.deploy(
        owner,
        dataStorageContract.address,
        standardStorageContract.address,
        chainAddress,
        oracleAddress,
        jobId,
        fee,
        dataEndpoint,
        { value: hre.ethers.utils.parseEther("0.001") }
    );
    await dataValidationContract.deployed();
    console.log("Data Validation contract deployed to:", dataValidationContract.address);

    const dataStoreContractFactory = await hre.ethers.getContractFactory('DataStore');
    const dataStoreContract = await dataStoreContractFactory.deploy(
        dataStorageContract.address,
        standardStorageContract.address,
        dataValidationContract.address,
        standardValidationContract.address,
        { value: hre.ethers.utils.parseEther("0.001") }
    );
    await dataStoreContract.deployed();
    console.log("Data Store contract deployed to:", dataStoreContract.address);


    let setStandardStorageSurface = await standardStorageContract.changeSurfaceAddress(dataStoreContract.address);
    await setStandardStorageSurface.wait();

    let setStandardStorageValidation = await standardStorageContract.changeStandardValidationAddress(standardValidationContract.address);
    await setStandardStorageValidation.wait();

    let setStandardStorageVisibilityStorage = await standardStorageContract.changeStandardVisibilityStorageAddress(dataStorageContract.address);
    await setStandardStorageVisibilityStorage.wait();

    let setStandardStorageVisibilityValidation = await standardStorageContract.changeStandardVisibilityValidationAddress(dataValidationContract.address);
    await setStandardStorageVisibilityValidation.wait();

    console.log("Set up Standard Storage");

    let setDataStorageSurface = await dataStorageContract.changeSurfaceAddress(dataStoreContract.address);
    await setDataStorageSurface.wait();

    let setDataStorageValidation = await dataStorageContract.changeDataValidationAddress(dataValidationContract.address);
    await setDataStorageValidation.wait();

    console.log("Set up Data Storage");

    let setStandardValidationSurface = await standardValidationContract.changeSurfaceAddress(dataStoreContract.address);
    await setStandardValidationSurface.wait();

    console.log("Set up Standard Validation");

    let setDataValidationContract = await dataValidationContract.changeSurfaceAddress(dataStoreContract.address);
    await setDataValidationContract.wait();

    console.log("Set up Data Validation");

    console.log("All Contracts deployed");
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