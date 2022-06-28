





































































// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PyeStake is ERC20, Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => Staker) public Stakers;

    address public PYE;

    uint8 constant _decimals = 0;

    constructor() ERC20("PYEStakeToken", "PYESTAKE") {}

    struct Staker {
        uint256 stakedBalance;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    // ---------------- Getter Functions ------------------

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function getStakedBalance(address _staker) public view returns (uint256) {
        return Stakers[_staker].stakedBalance;
    }

    function getTotalOwnedBalance(address _staker) public view returns (uint256) {
        return getStakedBalance(_staker).add(getBalanceOf(_staker));
    }

    function getBalanceOf(address _holder) public view returns (uint256) {
        return IERC20(PYE).balanceOf(address(_holder));
    }

    // ---------------- Modified Transfer Function ------------------


    // user cannot sell, transfer, or burn their StakeToken
    function transfer(address _to, uint256 _amount) public override notContract() nonReentrant returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) override internal {
        require(Stakers[_from].stakedBalance > 0 && IERC20(address(this)).balanceOf(address(_from)) > 0, 
        "You are not staked, or you do not have a StakeToken");
        
        _beforeTokenTransfer(_from, _to, _amount);

       
    }





    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function deposit(uint256 _amount) public nonReentrant notContract() {
        if (Stakers[msg.sender].stakedBalance == 0) {_mint(msg.sender, 1);}
        IERC20(PYE).safeTransferFrom(address(msg.sender), address(this), _amount);
        Stakers[msg.sender].stakedBalance += _amount;
    }




    //function withdraw(uint256)

}
