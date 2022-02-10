/* The following below contains the majority of the code for TokenA. Some proprietary functions and 
 information were removed. If all this is compiled together it will not work. I have IERC20 imported right
 now and will overlap some so I know that exists at the moment, changed the mint line to
 include IERC, and the secondary token had already been set as an IERC20 address.

 Like before, with the code compiled fully while commenting out the mint functions compiles and
 works just fine. When all compiled on the contract this is the error I receive

TypeError: Member "_mint" not found or not visible after argument-dependent lookup in contract IERC20.
     --> V4tst.sol:545:9:
     |
 25  |      tokenB._mint(recipient, amountTokenB);
     |         ^^^^^^^^^^^^^^^^^^


 As a recap, this token will send out BUSD reflection rewards to the platform user, as well as
 mint an additional zero value token to the user defined criteria and amount by other functions.
 The second token will not be tradeable, at least at first, and will be toggled active or not for 
trading later which I will handle in the other contract. The purpose of the second token is essentially proof of activity.
*/



//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.5;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

/*
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/*
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract V4TST is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address secondTokenFinal;

    string constant _name = "V4TST";
    string constant _symbol = "V4TST";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;

    bool public isSecondTokenSet = false;

    uint256 secondRate = 2;
    uint256 secondSpeed = totalFee.div(10);
    uint256 amountSecond = (secondRate ** secondModifier ** secondSpeed);
    uint256 secondModifier = 1;

    address public businessFeeReceiver;

    IDEXRouter public router;
    address public pair;

    address constant private _routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;

    uint256 public swapThresholdDen = 1; 
    uint256 public swapThreshold = _totalSupply.div(swapThresholdDen); 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router));
        
        isFeeExempt[_presaler] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        businessFeeReceiver = msg.sender;

        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function transfer(address recipient, uint256 amount) external override returns (bool) {
        IERC20(secondTokenFinal)._mint(recipient, amountSecondTotal);
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
          // check if this is the liquidity adding tx to startup.
          if(!hasLiquidityBeenAdded) {
            _checkLiquidityAdd(recipient, sender);
          } else {
            if(
              launchedAt > 0
                && sender == pair
                && sender != owner
                && recipient != owner
            ) 
          }
    }          
        
        _transactionBlockLog[recipient] =block.number;
        
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if( recipient != pair && recipient != _routerAddress && sender != owner && recipient != owner && sender != address(this) && recipient != address(this)) {
           require(balanceOf(recipient) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
        }   
        
        bool isTransferBetweenWallets;
        if (sender != owner && recipient != owner && sender != pair && recipient != pair && !isContract(sender) && !isContract(recipient)) {
        isTransferBetweenWallets = true;
        
        if (isTransferBetweenWallets){
            cloneSellDataToTransferWallet(sender, recipient);
        }
        }

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        IERC20(secondTokenFinal)._mint(recipient, amountSecond);
        return true;
    }
    

    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

   

    function setSecondTokenFinal(address _secondtoken) external onlyOwner {
        secondTokenFinal = (_secondtoken);
        isSecondTokenSet = true;
    }
