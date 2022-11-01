const FakeToken2 = artifacts.require("FakeToken2");
module.exports = function (deployer) {
    deployer.deploy(FakeToken2);
};
