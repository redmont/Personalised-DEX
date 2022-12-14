// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./baseContract.sol";
import "./Traders.sol";
import "hardhat/console.sol";

contract OrdersManagement is Helper, Traders {
    /* This contract has following functionalities
     1. Create Limit order
     2. Create Market order
     3. Update order book
     4. update trader balances
     */

    enum Side {
        BUY,
        SELL
    }
    uint256 lastOrderID;

    struct Order {
        uint256 id;
        address trader;
        bytes32 ticker;
        Side side;
        uint256 amount;
        uint256 price;
        uint256 filledAmount;
    }

    event NewTrade(
        address trader,
        bytes32 ticker,
        Side side,
        uint256 amount,
        uint256 averagePrice,
        uint256 filled
    );
    event log(uint256 c);

    mapping(bytes32 => mapping(Side => Order[])) OrderBook;

    function LimitOrder(
        bytes32 ticker,
        Side side,
        uint256 amount,
        uint256 price
    ) external isTokenExist(ticker) {
        if (side == Side.BUY) {
            // trader must have enough DAI tokens
            uint256 requiredDaiTokens = amount * price;
            require(
                requiredDaiTokens <= getBalance(DAI, msg.sender),
                "You don't have enough DAI"
            );
        } else {
            // trader must have enough ticker tokens
            require(
                amount <= getBalance(ticker, msg.sender),
                string.concat(
                    "You don't have enough ",
                    string(abi.encodePacked(ticker))
                )
            );
        }

        Order[] storage orders = OrderBook[ticker][side];

        Order memory neworder = Order(
            lastOrderID + 1,
            msg.sender,
            ticker,
            side,
            amount,
            price,
            0
        );

        // Create an order in order book
        OrderBook[ticker][side] = InsertInOrdersArray(neworder, orders);
        lastOrderID++;
    }

    function MarketOrder(
        bytes32 ticker,
        Side side,
        uint256 amount
    ) public isTokenExist(ticker) {
        if (side == Side.BUY) {
            // Right now we don't know how much DAI tokens are required
        } else {
            // trader must have enough ticker tokens
            require(
                amount <= getBalance(ticker, msg.sender),
                string.concat(
                    "You don't have enough ",
                    string(abi.encodePacked(ticker))
                )
            );
        }

        // Going through the Order Book to find the best match
        // orders is an ascending array [4]
        // If buy order, then we interseted in lowest price. left to right in the array
        // If sell order, then we interseted in highest price. right to left in the array
        Order[] storage orders = OrderBook[ticker][
            side == Side.BUY ? Side.SELL : Side.BUY
        ];
        uint256 tradeRemainingToBefilled = amount; //2
        int256 i = (side == Side.BUY) ? int256(0) : int256(orders.length) - 1; //0

        // to calculate average price
        uint256 totalPrice;
        uint256 totalTrades;

        while (
            tradeRemainingToBefilled != 0 && i > -1 && i < int256(orders.length)
        ) {
            // current order in orderbook
            Order storage currentOrder = orders[uint256(i)];
            uint256 availableCurrentOrder = currentOrder.amount -
                currentOrder.filledAmount;

            uint256 processAmount;

            if (availableCurrentOrder >= tradeRemainingToBefilled) {
                processAmount = tradeRemainingToBefilled;
            } else {
                processAmount = availableCurrentOrder;
            }

            if (side == Side.BUY) {
                // Now we know the price, checking if trader have enough DAI
                uint256 DaiRequired = processAmount * currentOrder.price;
                require(
                    tradersBalances[msg.sender][DAI] >= DaiRequired,
                    "Not enough DAI"
                );
            }

            // upadate order book
            orders[uint256(i)].filledAmount += processAmount;

            if (side == Side.BUY) {
                // update market order trader's balance
                tradersBalances[msg.sender][ticker] += processAmount;
                tradersBalances[msg.sender][DAI] -=
                    processAmount *
                    currentOrder.price;

                // update limit order trader's balance
                tradersBalances[currentOrder.trader][ticker] -= processAmount;
                tradersBalances[currentOrder.trader][DAI] +=
                    processAmount *
                    currentOrder.price;
            } else {
                // update market order trader's balance
                tradersBalances[msg.sender][ticker] -= processAmount;
                tradersBalances[msg.sender][DAI] +=
                    processAmount *
                    currentOrder.price;

                // update limit order trader's balance
                tradersBalances[currentOrder.trader][ticker] += processAmount;
                tradersBalances[currentOrder.trader][DAI] -=
                    processAmount *
                    currentOrder.price;
            }

            tradeRemainingToBefilled -= processAmount;

            totalPrice += currentOrder.price;
            totalTrades++;

            // if buy order, iterate to right and vice versa

            side == Side.BUY ? i++ : i--;
        }

        clearOrderBook(orders, side);

        if (totalTrades > 0) {
            uint256 filled = ((amount - tradeRemainingToBefilled) * 100) /
                amount;
            uint256 averagePrice = totalPrice / totalTrades;

            emit NewTrade(
                msg.sender,
                ticker,
                side,
                amount,
                averagePrice,
                filled
            );
        }
    }

    function getOrders(bytes32 ticker, Side side)
        external
        view
        returns (Order[] memory)
    {
        return OrderBook[ticker][side];
    }

    // Remove orders that are filled from order book

    function clearOrderBook(Order[] storage _orders, Side last_side)
        private
        returns (Order[] storage)
    {
        int256 i = last_side == Side.BUY
            ? int256(0)
            : int256(_orders.length) - 1;
        while (
            i < int256(_orders.length) &&
            i > -1 &&
            _orders[uint256(i)].filledAmount == _orders[uint256(i)].amount
        ) {
            if (last_side == Side.BUY) {
                for (uint256 j = 0; j < (_orders.length) - 1; j++) {
                    _orders[j] = _orders[j + 1];
                }
                _orders.pop();
            } else {
                _orders.pop();
            }
            last_side == Side.BUY ? i++ : i--;
        }
        return _orders;
    }

    function InsertInOrdersArray(Order memory order, Order[] storage _orders)
        private
        returns (Order[] storage)
    {
        _orders.push(order);
        for (uint256 i = _orders.length - 1; i == 1; i--) {
            if (_orders[i].price >= _orders[i - 1].price) {
                break;
            }
            // swap to left
            Order memory temp = _orders[i - 1];
            _orders[i - 1] = _orders[i];
            _orders[i] = temp;
        }
        return _orders;
    }
}
