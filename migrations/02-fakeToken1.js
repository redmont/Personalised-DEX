const FakeToken1 = artifacts.require("FakeToken1");
module.exports = function (deployer) {
    deployer.deploy(FakeToken1);
};
