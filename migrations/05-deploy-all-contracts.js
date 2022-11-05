const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const Dex = artifacts.require("Dex");
const fakeDAI = artifacts.require("FakeDai");
const fakeToken1 = artifacts.require("FakeToken1");
const fakeToken2 = artifacts.require("fakeToken2");

const [DEX, DAI, FT1, FT2] = ["DEX", "DAI", "FT1", "FT2"].map((ticker) =>
    web3.utils.asciiToHex(ticker),
);

const [BUY, SELL] = [0, 1];

module.exports = async function (deployer, networks, accounts) {
    const [trader1, trader2] = [accounts[1], accounts[2]];

    // 1. Ddeploying
    await Promise.all(
        [Dex, fakeDAI, fakeToken1, fakeToken2].map((contract) =>
            deployer.deploy(contract),
        ),
    );

    // 2. Getting instances of deployed
    const [_dex, _dai, _ft1, _ft2] = await Promise.all(
        [Dex, fakeDAI, fakeToken1, fakeToken2].map((contract) =>
            contract.deployed(contract),
        ),
    );

    // 3. Add fake tokens to the exchange
    await Promise.all([
        _dex.addNewToken(DAI, "DAI Stable Coin", _dai.address),
        _dex.addNewToken(FT1, "Fake Token 1", _ft1.address),
        _dex.addNewToken(FT2, "Fake Token 2", _ft2.address),
    ]);

    // 4. drop some tokens to traders account
    // and deposit some into exchange

    const amount = web3.utils.toWei("100");
    const depositAmount = web3.utils.toWei("50");

    const seedTokenBalance = async (tokenContract, trader) => {
        // Adding faucet of fake tokens to traders
        await tokenContract.faucet(trader, amount);

        // Approving these tokens to DEX
        // (When DEX will try to fetch these tokens by using transferFrom function of this token contract)
        await tokenContract.approve(_dex.address, amount, {
            from: trader,
        });

        // Deposit some tokens on exchange
        let ticker = await tokenContract.name();
        ticker = web3.utils.asciiToHex(ticker);

        await _dex.deposit(ticker, depositAmount, {
            from: trader,
        });
    };

    await seedTokenBalance(_dai, trader1);
    await seedTokenBalance(_dai, trader2);
    await seedTokenBalance(_ft1, trader1);
    await seedTokenBalance(_ft1, trader2);

    // 5. Create orders

    await _dex.LimitOrder(FT1, BUY, web3.utils.toWei("4"), 2, {
        from: trader1,
    });
    await _dex.MarketOrder(FT1, SELL, web3.utils.toWei("4"), {
        from: trader2,
    });

    await _dex.LimitOrder(FT1, SELL, web3.utils.toWei("3"), 2, {
        from: trader1,
    });
    await _dex.MarketOrder(FT1, BUY, web3.utils.toWei("4"), {
        from: trader2,
    });

    await _dex.LimitOrder(FT1, SELL, web3.utils.toWei("4"), 2, {
        from: trader1,
    });
    await _dex.MarketOrder(FT1, BUY, web3.utils.toWei("2"), {
        from: trader2,
    });

    await _dex.LimitOrder(FT1, SELL, web3.utils.toWei("1"), 2, {
        from: trader1,
    });
    await _dex.LimitOrder(FT1, SELL, web3.utils.toWei("1"), 2, {
        from: trader1,
    });
    await _dex.MarketOrder(FT1, BUY, web3.utils.toWei("4"), {
        from: trader2,
    });

    console.log(await _dex.getOrders(FT1, 0));
    console.log("SELL");
    console.log(await _dex.getOrders(FT1, 1));
};
