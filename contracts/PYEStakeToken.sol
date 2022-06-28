// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PyeStakeToken is ERC20, Ownable {

    address public stakingContract;
    mapping(address => uint256) public Balances;
    uint256 public _tTotal;
    
    uint8 constant _decimals = 0;

    event StakeTokenBurned(address _account, address destination, uint256 _amount);
    event StakeTokenMinted(address _account, address destination, uint256 _amount);

    modifier onlyStakingContract() {
        require(stakingContract != address(0) , "Staking contract hasn't been set!");
        require(msg.sender == stakingContract , "Only PYEStakingContract!");
        _;
    }

    constructor(address _stakingContract) ERC20("PyeStakeToken", "PYESTAKETOKEN") {
        stakingContract = _stakingContract;
    }

    // --------- Setter Fxns ----------

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }

    // --------- Getter Fxns ----------

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return Balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    // --------- Modified Transfer Fxns ----------

    // unused function params are left in to keep function signatures 
    // the same as ERC-20 parent functions, otherwise override modifier won't work

    function transfer(address to, uint256 amount) public view override returns (bool) {
        revert("Stake token is non-transferrable");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public view override returns (bool) {
        revert("Stake token is non-transferrable");
    }

    // --------- Modified Burn Fxns ----------

    function burnStakeToken(address _staker, uint256 _amount) external onlyStakingContract() {
        _burn(_staker, _amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: cannot burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = Balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            Balances[account] = accountBalance - amount;
        }

        _tTotal -= amount;
        emit StakeTokenBurned(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    // --------- Modified Mint Fxns ----------
   
   function mintStakeToken(address _depositor, uint256 amount) external onlyStakingContract() {
       _mint(_depositor, amount);
    }

   function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: cannot mint to the zero address");
        require(Balances[account] == 0, "Already has stake token"); 
        _beforeTokenTransfer(address(0), account, amount);

        _tTotal += amount;
        Balances[account] += amount;
        emit StakeTokenMinted(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
        assert(amount == 1);
    }
}