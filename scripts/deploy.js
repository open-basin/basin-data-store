const hre = require("hardhat");

const main = async () => {
    const [owner] = await hre.ethers.getSigners();

    console.log("Deploying contracts with", owner.address);
    
    const standardStorageContractFactory = await hre.ethers.getContractFactory('StandardStorage');
    const standardStorageContract = await standardStorageContractFactory.deploy(
        owner.address, 
        owner.address, 
        owner.address,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await standardStorageContract.deployed();
    console.log("Standard Storage contract deployed to:", standardStorageContract.address);

    const dataStorageContractFactory = await hre.ethers.getContractFactory('DataStorage');
    const dataStorageContract = await dataStorageContractFactory.deploy(
        owner.address, 
        owner.address, 
        standardStorageContract.address,
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await dataStorageContract.deployed();
    console.log("Data Storage contract deployed to:", dataStorageContract.address);

    const fee = 0.1 * 10 ** 18;
    
    const standardValidationContractFactory = await hre.ethers.getContractFactory('StandardValidation');
    const standardValidationContract = await standardValidationContractFactory.deploy(
        owner.address, 
        standardStorageContract.address, 
        "0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40", // TODO - Fix
        ethers.utils.formatBytes32String(""), // TODO - Fix
        ethers.utils.parseEther(`${fee}`), // TODO - Fix
        "https://validate.rinkeby.openbasin.io/datastore/validate/standard",
        {value: hre.ethers.utils.parseEther("0.001")}
    );
    await standardValidationContract.deployed();
    console.log("Standard Validation contract deployed to:", standardValidationContract.address);

    const dataValidationContractFactory = await hre.ethers.getContractFactory('DataValidation');
    const dataValidationContract = await dataValidationContractFactory.deploy(
        owner.address, 
        dataStorageContract.address, 
        "0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40", // TODO - Fix
        ethers.utils.formatBytes32String(""), // TODO - Fix
        ethers.utils.parseEther(`${fee}`), // TODO - Fix
        "https://validate.rinkeby.openbasin.io/datastore/validate/data",
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


    let setDataStorageSurface = await dataStorageContract.changeSurfaceAddress(dataStoreContract.address);
    await setDataStorageSurface.wait();

    let setDataStorageValidation = await dataStorageContract.changeDataValidationAddress(dataValidationContract.address);
    await setDataStorageValidation.wait();


    let setStandardValidationSurface = await standardValidationContract.changeSurfaceAddress(dataStoreContract.address);
    await setStandardValidationSurface.wait();


    let setDataValidationContract = await dataValidationContract.changeSurfaceAddress(dataStoreContract.address);
    await setDataValidationContract.wait();

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