// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPYESwapRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
