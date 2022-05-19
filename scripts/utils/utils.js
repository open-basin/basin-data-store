
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

const structureStandard = (standard) => {
    return {
        token: standard.token.toNumber(),
        minter: standard.minter,
        name: standard.name,
        schema: standard.schema
    };
}


const structureStandards = (standards) => {
    return standards.map(standard => {
        return {
            token: standard.token.toNumber(),
            minter: standard.minter,
            name: standard.name,
            schema: standard.schema
        };
    });
}

const utils = {
    structureData,
    structureStandards,
    structureStandard,
    shrinkAddress
}

module.exports = { utils };