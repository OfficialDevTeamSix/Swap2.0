// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPYEStakeToken {
    function burnStakeToken(address _staker, uint256 _amount) external;
    function mintStakeToken(address _depositor, uint256 amount) external;
}