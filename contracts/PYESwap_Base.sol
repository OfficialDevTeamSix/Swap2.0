
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPYE.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPYESwapFactory.sol";
import "./interfaces/IPYESwapPair.sol";
import "./interfaces/IPYESwapRouter.sol";


contract PYESwap_Base is IPYE, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    
    // Fees
    // Add and remove fee types and destinations here as needed
    struct Fees {
        uint256 marketingFee;
        uint256 developmentFee;
        address marketingAddress;
        address developmentAddress;
    }

    // Transaction fee values
    // Add and remove fee value types here as needed
    struct FeeValues {
        uint256 transferAmount;
        uint256 marketing;
        uint256 development;
    }

    // Token details
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    // Set total supply here
    uint256 private _tTotal = 10 * 10**9 * 10**9;



    // Users states
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) isTxLimitExempt;


    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;


    // Set the name, symbol, and decimals here
    string constant _name = "PYESwap_Base";
    string constant _symbol = "BASE";
    uint8 constant _decimals = 9;

    Fees public _defaultFees;
    Fees private _previousFees;
    Fees private _emptyFees;

    IPYESwapRouter public pyeSwapRouter;
    address public pyeSwapPair;
    address public WBNB;
    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = 5 * 10**8 * 10**9;

    bool public swapEnabled = true;
    uint256 public swapThreshold = 5 * 10**14; // 0.0005 WBNB
    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyExchange() {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == msg.sender) isPair = true;
        }
        require(
            msg.sender == address(pyeSwapRouter)
            || isPair
            , "PYE: NOT_ALLOWED"
        );
        _;
    }

    // Edit the constructor in order to declare default fees on deployment
    constructor(address _router, address _marketing, uint256 _marketingFee, address _development, uint256 _developmentFee) {
        _balances[_msgSender()] = _tTotal;

        pyeSwapRouter = IPYESwapRouter(_router);
        WBNB = pyeSwapRouter.WETH();
        pyeSwapPair = IPYESwapFactory(pyeSwapRouter.factory())
        .createPair(address(this), WBNB, true, address(this));

        tokens[pairsLength] = WBNB;
        pairs[pairsLength] = pyeSwapPair;
        pairsLength += 1;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[pyeSwapPair] = true;

        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;

        // This should match the struct Fee
        _defaultFees = Fees(
            _marketingFee,
            _developmentFee,
            _marketing,
            _development
        );

        // IPYESwapPair(pyeSwapPair).updateTotalFee(500);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // function _updatePairsFee() internal {
    //     for (uint j = 0; j < pairsLength; j++) {
    //         IPYESwapPair(pairs[j]).updateTotalFee(getTotalFee());
    //     }
    // }


    // Functions to update fees and addresses 

    function setDevelopmentPercent(uint256 _developmentFee) external onlyOwner {
        _defaultFees.developmentFee = _developmentFee;
    }

    function setDevelopmentAddress(address _development) external onlyOwner {
        require(_development != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.developmentAddress = _development;
    }

    function setMarketingPercent(uint256 _marketingFee) external onlyOwner {
        _defaultFees.marketingFee = _marketingFee;
    }

    function setMarketingAddress(address _marketing) external onlyOwner {
        require(_marketing != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.marketingAddress = _marketing;
    }



    function updateRouterAndPair(address _router, address _pair) public onlyOwner {
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WBNB = pyeSwapRouter.WETH();

        _isExcludedFromFee[pyeSwapPair] = true;

        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WBNB;

        // IPYESwapPair(pyeSwapPair).updateTotalFee(getTotalFee());
    }

    // To update the max tx amount
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    //to receive BNB from pyeRouter when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            0,
            calculateFee(tAmount, _defaultFees.marketingFee),
            calculateFee(tAmount, _defaultFees.developmentFee)
        );

        values.transferAmount = tAmount.sub(values.marketing).sub(values.development);
        return values;
    }

    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount.mul(_fee).div(
            10**4
        );
    }

    function removeAllFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _emptyFees;
    }

    function restoreAllFee() private {
        _defaultFees = _previousFees;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getBalance(address keeper) public view returns (uint256){
        return _balances[keeper];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        checkTxLimit(from, amount);

        //indicates if fee should be deducted from transfer of tokens
        bool takeFee = false;

        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount, takeFee);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

    function getTotalFee() internal view returns (uint256) {
        return _defaultFees.marketingFee
            .add(_defaultFees.developmentFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        }

        FeeValues memory _values = _getValues(amount);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(_values.transferAmount);
        _takeFees(_values);

        emit Transfer(sender, recipient, _values.transferAmount);

        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _takeFees(FeeValues memory values) private {
        _takeFee(values.marketing, _defaultFees.marketingAddress);
        _takeFee(values.development, _defaultFees.developmentAddress);
    }

    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[address(this)] = _balances[address(this)].add(tAmount);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    // This function transfers the fees to the correct addresses. 
    function handleFee(uint256 amount, address token) public onlyExchange {
        uint256 tokenIndex = _getTokenIndex(token);
        if(tokenIndex < pairsLength) {
            uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));
            if(allowanceT >= amount) {
                IERC20(token).transferFrom(msg.sender, address(this), amount);

                // All fees to be declared here in order to be calculated and sent
                uint256 totalFee = getTotalFee();
                uint256 marketingFeeAmount = amount.mul(_defaultFees.marketingFee).div(totalFee);
                uint256 developmentFeeAmount = amount.mul(_defaultFees.developmentFee).div(totalFee);

                IERC20(token).transfer(_defaultFees.marketingAddress, marketingFeeAmount);
                IERC20(token).transfer(_defaultFees.developmentAddress, developmentFeeAmount);
            }
        }
    }

    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }

        return index;
    }

    function addPair(address _pair, address _token) public {
        address factory = pyeSwapRouter.factory();
        require(
            msg.sender == factory
            || msg.sender == address(pyeSwapRouter)
            || msg.sender == address(this)
        , "PYE: NOT_ALLOWED"
        );

        if(!_checkPairRegistered(_pair)) {
            _isExcludedFromFee[_pair] = true;
            isTxLimitExempt[_pair] = true;

            pairs[pairsLength] = _pair;
            tokens[pairsLength] = _token;

            pairsLength += 1;

            // IPYESwapPair(_pair).updateTotalFee(getTotalFee());
        }
    }

    function _checkPairRegistered(address _pair) internal view returns (bool) {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == _pair) isPair = true;
        }

        return isPair;
    }

    // Rescue bnb that is sent here by mistake
    function rescueBNB(uint256 amount, address to) external onlyOwner{
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }
}
