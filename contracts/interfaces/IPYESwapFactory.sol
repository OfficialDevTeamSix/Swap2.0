// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPYESwapFactory {
    function createPair(address tokenA, address tokenB, bool supportsTokenFee, address feeTaker) external returns (address pair);
}
