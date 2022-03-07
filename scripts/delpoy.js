const main = async () => {
    const ocDataStoreFactory = await hre.ethers.getContractFactory('BasinDataStore');
    const ocDataStoreContract = await ocDataStoreFactory.deploy({
        value: hre.ethers.utils.parseEther("0.001"),
    });

    await ocDataStoreContract.deployed();

    console.log("Contract deployed to:", ocDataStoreContract.address);
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