// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPYEStakeToken.sol";

contract PYEStakingContract is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public StakedBalance;

    IPYEStakeToken public PYEStakeTokenInterface;
    address public PYEStakeTokenAddress;
    address public PYE;

    constructor(address _PYE) {
        PYE = _PYE;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // ------------ Setter Fxns ---------------

    function setPYEStakeToken(address _address) external onlyOwner {
        PYEStakeTokenAddress = _address;
        PYEStakeTokenInterface = IPYEStakeToken(_address);
    }

    function setPYE(address _address) external onlyOwner {
        PYE = _address;
    }

    // ------------ Getter Fxns ---------------

    function getStakedBalance(address _staker) public view returns (uint256) {
        return StakedBalance[_staker];
    }

    function getPYEBalance(address _holder) public view returns (uint256) {
        return IERC20(PYE).balanceOf(address(_holder));
    }

    function getTotalOwnedBalance(address _address) public view returns (uint256) {
        return getStakedBalance(_address).add(getPYEBalance(_address));
    }

    // ------------ Deposit Fxn ---------------

    function deposit(uint256 _amount) public nonReentrant notContract() {
        if (Stakers[msg.sender].stakedBalance == 0) {_mint(msg.sender, 1);}
        IERC20(PYE).safeTransferFrom(address(msg.sender), address(this), _amount);
        Stakers[msg.sender].stakedBalance += _amount;
    }
}