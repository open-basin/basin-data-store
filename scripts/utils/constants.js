// constants.js

const utf8Encode = new TextEncoder();

const constants = {
    rinkeby: {
        chainAddress: "0x01BE23585060835E02B77ef475b0Cc51aA1e0709",
        oracleAddress: "0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40",
        jobId: utf8Encode.encode("e5b0e6aeab36405ba33aea12c6988ed6"),
        standardEndpoint: "https://validate.rinkeby.openbasin.io/datastore/validate/standard",
        dataEndpoint: "https://validate.rinkeby.openbasin.io/datastore/validate/data"
    }, 
    goerli: {
        chainAddress: "0x326c977e6efc84e512bb9c30f76e30c160ed06fb",
        oracleAddress: "",
        jobId: utf8Encode.encode(""),
        standardEndpoint: "https://validate.goerli.openbasin.io/datastore/validate/standard",
        dataEndpoint: "https://validate.goerli.openbasin.io/datastore/validate/data"
    },
    kovan: {
        chainAddress: "0xa36085F69e2889c224210F603D836748e7dC0088",
        oracleAddress: "0xF405B99ACa8578B9eb989ee2b69D518aaDb90c1F",
        jobId: utf8Encode.encode("c51694e71fa94217b0f4a71b2a6b565a"),
        standardEndpoint: "https://validate.kovan.openbasin.io/datastore/validate/standard",
        dataEndpoint: "https://validate.kovan.openbasin.io/datastore/validate/data"
    }, 
    fee: 0.1 * 10 ** 18
}

module.exports = { constants };