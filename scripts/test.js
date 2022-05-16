const hre = require("hardhat");

const main = async () => {
    const owner = process.env.PUBLIC_KEY;

    console.log("Deploying contracts with", owner);

    const dataStoreContract = await hre.ethers.getContractAt('DataStore',"0x2EF6eFD1E9E0eBAca0f94575783EEF8a164513E0");
    console.log("DataStore contract:", dataStoreContract.address);

    var standards = [];

    console.log("----------------------- Create Standard");

    // let createStandard = await dataStoreContract.storeStandard("Zero", "{}", { value: hre.ethers.utils.parseEther("0.001") });
    // await createStandard.wait();

    standards = await dataStoreContract.allStandards();
    console.log("standards:", structureStandards(standards));
};

const shrinkAddress = (addr) => {
    if (addr.length < 14) {
        return addr;
    }
    return addr.slice(0, 4) + '..' + addr.slice(-3);
}

const structureData = (data) => {
    return data.map(payload => {
        return {
            token: payload.token.toNumber(),
            owner: payload.owner,
            standard: payload.standard.toNumber(),
            timestamp: new Date(payload.timestamp * 1000).toGMTString(),
            payload: payload.payload,
        };
    });
}

const structureStandards = (standards) => {
    return standards.map(standard => {
        return {
            token: standard.token.toNumber(),
            name: standard.name,
            schema: standard.schema,
            exists: standard.exists
        };
    });
}

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