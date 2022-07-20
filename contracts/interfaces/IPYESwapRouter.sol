// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPYESwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
