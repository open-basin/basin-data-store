const hre = require("hardhat");
const { utils } = require("./utils/utils.js");

const main = async () => {
    const standardStorageContract = await hre.ethers.getContractAt('StandardStorage',"0xeA6B899Dd08E5528134f3Ec3FBA211c4ED8a0f98");
    const dataStorageContract = await hre.ethers.getContractAt('DataStorage',"0x2431E1eeE451E650A0Dd32fdBd7b71D94AD17a98");
    const standardValidationContract = await hre.ethers.getContractAt('StandardValidation',"0x194b010e83ad09bE2e0937cc8c76CF977418C27b");
    const dataValidationContract = await hre.ethers.getContractAt('DataValidation',"0x2A40aF869Bf5245DBA174dD01676f8b5F0f43DB0");
    const dataStoreContract = await hre.ethers.getContractAt('DataStore',"0x67d821C1784A98b62C654e2FDC6A949B89e719fF");

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