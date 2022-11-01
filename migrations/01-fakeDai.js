const FakeDai = artifacts.require("FakeDai");
module.exports = function (deployer) {
    deployer.deploy(FakeDai);
};
