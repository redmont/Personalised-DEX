// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./baseContract.sol";
import "./Traders.sol";

contract OrdersManagement is Helper, traders {
    /* This contract has following functionalities
     1. Create Limit order
     2. Create Market order
     */

    enum Side {
        BUY,
        SELL
    }
    struct Order {
        uint256 id;
        bytes32 ticker;
        Side side;
        uint256 amount;
        uint256 price;
        uint256 filledAmount;
    }

    uint256 lastOrderID;

    mapping(bytes32 => mapping(Side => Order[])) OrderBook;

    function LimitOrder(
        bytes32 ticker,
        Side side,
        uint256 amount,
        uint256 price
    ) external isTokenExist(ticker) {
        Order[] storage orders = OrderBook[ticker][side];

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

        Order memory neworder = Order(
            lastOrderID + 1,
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
