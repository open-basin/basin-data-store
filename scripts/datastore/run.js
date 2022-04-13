const hre = require("hardhat");

const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const contractFactory = await hre.ethers.getContractFactory('DataStore');
    const contract = await contractFactory.deploy();
    await contract.deployed();

    console.log("Contract deployed to:", contract.address);
    console.log("Contract deployed by:", owner.address);

    var standards = [];

    console.log("----------------------- Create Standard");

    let createStandard = await contract.createStandard("Zero", "{}");
    await createStandard.wait();

    standards = await contract.allStandards();
    console.log("standards:", structureStandards(standards));

    console.log("----------------------- Store Data");

    let storeData1 = await contract.storeData(owner.address, 0, "{}");
    await storeData1.wait();

    await logData(contract, [owner.address, randomPerson.address]);

    console.log("----------------------- Data Transfer");

    let transfer1 = await contract.transferData(0, randomPerson.address);
    await transfer1.wait();

    await logData(contract, [owner.address, randomPerson.address]);

    console.log("----------------------- Store Data");

    let storeData2 = await contract.storeData(owner.address, 0, "{}");
    await storeData2.wait();

    await logData(contract, [owner.address, randomPerson.address]);

    console.log("----------------------- Burn Data");

    let burn = await contract.burnData(1);
    await burn.wait();

    await logData(contract, [owner.address, randomPerson.address]);
};

const logData = async (contract, addresses) => {
    for (var i = 0; i < addresses.length; i++) {
        const data = await contract.dataForOwner(addresses[i]);
        console.log(shrinkAddress(addresses[i]) + ":", structureData(data));
    }
}

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
        console.log(error);
        process.exit(1);
    }
};

runMain();