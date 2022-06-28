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
    uint256 public totalStakedPYE;

    IPYEStakeToken public PYEStakeTokenInterface;
    address public PYEStakeTokenAddress;
    address public PYE;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier addressCheck {
        require(PYEStakeTokenAddress != address(0), "PYEStakeTokenAddress hasn't been set yet!");
        _;
    }

    constructor(address _PYE) {
        PYE = _PYE;
    }

    event StakedAndMinted(address indexed _address, uint256 _blockTimestamp);
    event UnstakedAndBurned(address indexed _address, uint256 _blockTimestamp);

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

    function deposit(uint256 _amount) external addressCheck nonReentrant notContract() {
        uint256 currentStakedBalance = StakedBalance[msg.sender];
        if (currentStakedBalance == 0) {
            PYEStakeTokenInterface.mintStakeToken(msg.sender, 1);
            emit StakedAndMinted(msg.sender, block.timestamp);
        } else {
            IERC20(PYE).safeTransferFrom(address(msg.sender), address(this), _amount);
            StakedBalance[msg.sender] += _amount;
            totalStakedPYE += _amount;
        }
    }

    // ------------ Withdraw Fxn ---------------

    function withdraw(uint256 _amount) external addressCheck nonReentrant notContract() {
        require(StakedBalance[msg.sender] >= _amount , "Withdrawl amount exceeds balance!");
        uint256 currentStakedBalance = StakedBalance[msg.sender];
        uint256 PYEStakeTokenBalance = IERC20(PYEStakeTokenAddress).balanceOf(msg.sender);

        if (currentStakedBalance.sub(_amount) == 0) {
            PYEStakeTokenInterface.burnStakeToken(msg.sender, PYEStakeTokenBalance);
            IERC20(PYE).safeTransfer(msg.sender, _amount);
            StakedBalance[msg.sender] = 0;
            totalStakedPYE -= _amount;
            emit UnstakedAndBurned(msg.sender, block.timestamp);
        } else {
            IERC20(PYE).safeTransfer(msg.sender, _amount);
            StakedBalance[msg.sender] -= _amount;
            totalStakedPYE -= _amount;
        }
    }


}