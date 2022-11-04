const { expectRevert } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const Dex = artifacts.require("Dex");
const fakeDAI = artifacts.require("FakeDai");
const fakeToken1 = artifacts.require("FakeToken1");
const fakeToken2 = artifacts.require("fakeToken2");

contract("Dex", (accounts) => {
    const amount = web3.utils.toWei("100");
    let DEX, DAI, FT1, FT2;
    const [trader1, trader2] = [accounts[1], accounts[2]];

    before(async () => {
        // Deploy all fake tokens contract
        [DAI, FT1, FT2] = await Promise.all([
            fakeDAI.deployed(),
            fakeToken1.deployed(),
            fakeToken2.deployed(),
        ]);

        // Deploy DEX contract
        DEX = await Dex.deployed();

        // Add fake tokens to the exchange
        await Promise.all([
            DEX.addNewToken(
                web3.utils.asciiToHex("DAI"),
                "DAI Stable Coin",
                DAI.address,
            ),
            DEX.addNewToken(
                web3.utils.asciiToHex("FT1"),
                "Fake Token 1",
                FT1.address,
            ),
            DEX.addNewToken(
                web3.utils.asciiToHex("FT2"),
                "Fake Token 2",
                FT2.address,
            ),
        ]);

        const seedTokenBalance = async (tokenContract) => {
            // Adding faucet of fake tokens to traders
            await tokenContract.faucet(trader1, amount);
            await tokenContract.faucet(trader2, amount);

            // Approving these tokens to DEX (When DEX will try to fetch these tokens)
            await tokenContract.approve(DEX.address, amount, {
                from: trader1,
            });
            await tokenContract.approve(DEX.address, amount, {
                from: trader2,
            });
        };

        await seedTokenBalance(DAI);
        await seedTokenBalance(FT1);
        await seedTokenBalance(FT2);
    });

    it(
        "should deposit " + amount + " tokens to DEX in traders wallet",
        async () => {
            const depositAmount = web3.utils.toWei("10");

            await DEX.deposit(web3.utils.asciiToHex("DAI"), depositAmount, {
                from: trader1,
            });

            const balance = await DEX.getBalance(
                web3.utils.asciiToHex("DAI"),
                trader1,
            );

            assert.equal(
                balance.toString(),
                depositAmount,
                "Balance did not matched",
            );
        },
    );

    // UNHAPPY PATH
    it("should not deposit invalid tokens to DEX in traders wallet", async () => {
        const depositAmount = web3.utils.toWei("10");
        await expectRevert(
            DEX.deposit(web3.utils.asciiToHex("XRP"), depositAmount, {
                from: trader1,
            }),
            "The token does not exist",
        );
    });

    it("should create 3 limit order in the correct order", async () => {
        // deposit DAI
        const depositAmount = web3.utils.toWei("10");
        await DEX.deposit(web3.utils.asciiToHex("DAI"), depositAmount, {
            from: trader1,
        });

        await DEX.LimitOrder(web3.utils.asciiToHex("FT1"), 0, 10, 3, {
            from: trader1,
        });
        await DEX.LimitOrder(web3.utils.asciiToHex("FT1"), 0, 10, 2, {
            from: trader1,
        });
        await DEX.LimitOrder(web3.utils.asciiToHex("FT1"), 0, 10, 4, {
            from: trader1,
        });

        const buyOrders = await DEX.getOrders(web3.utils.asciiToHex("FT1"), 0);

        assert.equal(web3.utils.hexToUtf8(buyOrders[0].ticker), "FT1");

        assert.equal(buyOrders[0].price, 2);
        assert.equal(buyOrders[2].price, 4);
    });

    it("should create a market order & match against existing limit orders", async () => {
        // Trader 1
        // deposit DAI
        const depositAmount = web3.utils.toWei("10");
        await DEX.deposit(web3.utils.asciiToHex("DAI"), depositAmount, {
            from: trader1,
        });

        await DEX.LimitOrder(
            web3.utils.asciiToHex("FT1"),
            0,
            web3.utils.toWei("2"),
            3,
            {
                from: trader1,
            },
        );
        await DEX.LimitOrder(
            web3.utils.asciiToHex("FT1"),
            0,
            web3.utils.toWei("4"),
            2,
            {
                from: trader1,
            },
        );

        console.log(await DEX.getOrders(web3.utils.asciiToHex("FT1"), 0));
        // Trader 2
        await DEX.deposit(web3.utils.asciiToHex("FT1"), depositAmount, {
            from: trader2,
        });
        await DEX.MarketOrder(
            web3.utils.asciiToHex("FT1"),
            1,
            web3.utils.toWei("1"),
            {
                from: trader2,
            },
        );
        console.log("-----------------------------------------------------");
        console.log(await DEX.getOrders(web3.utils.asciiToHex("FT1"), 0));
    });
});
