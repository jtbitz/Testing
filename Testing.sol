//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.5;    

// ERC-20 Token

// The goal of this project is to give a group of users proof of activity through use of an additional zero value token.
// This token is to be sent to the user whenever they Buy, Sell or Transfer the token, Proof of Activity.
// Let's assume that this token will always retain zero value, and in the future may have the ability to exchange these tokens.
// Parameters for numbers of TokenB to be sent are defined within TokenA and through set functions.

// If there is a better method to accomplish this then I am definitely up to suggestions, once I figure this part out, I am done.

// All code in the contract works with the exceptoin of the _mint lines; if those are all commented out it compiles fine

// The following error occurs: 

//TypeError: Member "_mint" not found or not visible after argument-dependent lookup in address.
//     --> V4tst.sol:545:9:
//     |
// 25  |      tokenB._mint(recipient, amountTokenB);
//     |         ^^^^^^^^^^^^^^^^^^


// Below are the transfer functions within my TokenA contract


function transfer(address recipient, uint256 amount) external override returns (bool) {
        tokenB._mint(recipient, amountTokenB);
        return _transferFrom(msg.sender, recipient, amount);
    }

function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    
    
function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // A bunch of if statements
        tokenB._mint(recipient, amountTokenB);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
   
   
// I nested the mint function in the script in case it was needed   
   
       function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
