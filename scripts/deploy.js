const hre = require("hardhat");

const main = async () => {
    const owner = "0xe2eFc7F0D124B57B1F9a78164E1aBD0FDd337E1C";

    console.log("Deploying contracts with", owner);
    
    const standardStorageContractFactory = await hre.ethers.getContractFactory('StandardStorage');
    const standardStorageContract = await standardStorageContractFactory.deploy(
        owner, 
        owner, 
        owner,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await standardStorageContract.deployed();
    console.log("Standard Storage contract deployed to:", standardStorageContract.address);

    const dataStorageContractFactory = await hre.ethers.getContractFactory('DataStorage');
    const dataStorageContract = await dataStorageContractFactory.deploy(
        owner, 
        owner, 
        standardStorageContract.address,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await dataStorageContract.deployed();
    console.log("Data Storage contract deployed to:", dataStorageContract.address);
    
    let utf8Encode = new TextEncoder();
    const link = owner;
    const oracle = "0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40";
    const jobId = utf8Encode.encode("e5b0e6aeab36405ba33aea12c6988ed6");
    const fee = 0.1 * 10 ** 18;
    const url = "https://validate.goerli.openbasin.io/datastore/validate/standard"

    const standardValidationContractFactory = await hre.ethers.getContractFactory('StandardValidation');
    const standardValidationContract = await standardValidationContractFactory.deploy(
        owner, 
        standardStorageContract.address, 
        link,
        oracle,
        jobId,
        ethers.utils.parseEther(`${fee}`),
        url,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await standardValidationContract.deployed();
    console.log("Standard Validation contract deployed to:", standardValidationContract.address);

    const dataValidationContractFactory = await hre.ethers.getContractFactory('DataValidation');
    const dataValidationContract = await dataValidationContractFactory.deploy(
        owner, 
        dataStorageContract.address,
        link,
        oracle,
        jobId,
        ethers.utils.parseEther(`${fee}`),
        url,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await dataValidationContract.deployed();
    console.log("Data Validation contract deployed to:", dataValidationContract.address);

    const dataStoreContractFactory = await hre.ethers.getContractFactory('DataStore');
    const dataStoreContract = await dataStoreContractFactory.deploy(
        dataStorageContract.address,
        standardStorageContract.address, 
        dataValidationContract.address,
        standardValidationContract.address,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await dataStoreContract.deployed();
    console.log("Data Store contract deployed to:", dataStoreContract.address);


    let setStandardStorageSurface = await standardStorageContract.changeSurfaceAddress(dataStoreContract.address);
    await setStandardStorageSurface.wait();

    let setStandardStorageValidation = await standardStorageContract.changeStandardValidationAddress(standardValidationContract.address);
    await setStandardStorageValidation.wait();

    let setStandardStorageVisibility = await standardStorageContract.changeStandardVisibilityAddress(dataStorageContract.address);
    await setStandardStorageVisibility.wait();

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