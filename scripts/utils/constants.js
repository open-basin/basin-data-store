// constants.js

const utf8Encode = new TextEncoder();

const constants = {
    rinkeby: {
        chainAddress: "0x01BE23585060835E02B77ef475b0Cc51aA1e0709",
        oracleAddress: "0x9904415Db0B70fDd242b6Fe835d2bBc155466e8e",
        jobId: utf8Encode.encode("9a06f8e911874c55bf422d0d19a968b3"),
        fee: 0 * 10 * 18,
        standardEndpoint: "https://validate.rinkeby.openbasin.io/datastore/validate/standard",
        dataEndpoint: "https://validate.rinkeby.openbasin.io/datastore/validate/data"
    }, 
    goerli: {
        chainAddress: "0x326c977e6efc84e512bb9c30f76e30c160ed06fb",
        oracleAddress: "",
        jobId: utf8Encode.encode(""),
        fee: 0 * 10 * 18,
        standardEndpoint: "https://validate.goerli.openbasin.io/datastore/validate/standard",
        dataEndpoint: "https://validate.goerli.openbasin.io/datastore/validate/data"
    },
    kovan: {
        chainAddress: "0xa36085F69e2889c224210F603D836748e7dC0088",
        oracleAddress: "0xF405B99ACa8578B9eb989ee2b69D518aaDb90c1F",
        jobId: utf8Encode.encode("c51694e71fa94217b0f4a71b2a6b565a"),
        fee: 0 * 10 * 18,
        standardEndpoint: "https://validate.kovan.openbasin.io/datastore/validate/standard",
        dataEndpoint: "https://validate.kovan.openbasin.io/datastore/validate/data"
    }
}

module.exports = { constants };