// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./IERC20.sol";

contract CPAMM{
    //These are the two tokens the CPAMM will be dealing with
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    //This contract will keep internal balance of the two tokens
    uint public reserve0;
    uint public reserve1;

    //When the user provides or removes liquidity the user needs to mint or burn shares
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    constructor(address _token0, address _token1){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    //This is the function we use to mint shares
    function _mint(address _to,uint _amount) private{
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    //This is a function used to burn the shares
    function _burn(address _from,uint _amount) private{
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    //This update function is to update the reserves when called in the functions
    function _update(uint _reserve0, uint _reserve1) private{
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
    
    //Now we add a swap function this can be called by the users
    //tokenIn is the token which is coming in the pool
    //amountIn is the amount of that token coming in
    function swap(address _tokenIn, address _amountIn) external returns(uint amountOut){
        //We need to make sure that the tokenIn is either token0 or token1
        require(_tokenIn == address(token0) || _tokenIn == address(token1),"Invalid token");
        //Check if the amountIn is greater than 0
        require(_amountIn > 0 ,"amount In = 0");

        //Pull In tokenIn
        //Before pulling in we are checking if the tokenIn is token0 or token1
        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut ,uint reserveIn , uint reserveOut ) = 
        isToken0 ? (token0,token1 ,reserve0,reserve1) : (token1,token0,reserve1,reserve0);

        tokenIn.transferFrom(msg.sender,address(this),amountIn);

        //Calculate tokenOut,fee is 0.3%
        //From the math we know that the amount of tokens that go out are ydx / (x + dx) = dy
        uint amountInWithFee = [_amountIn * 997] / 1000;
        amountOut = (reserveOut*amountInWithFee) / (reserveIn + amountInWithFee);

        //Transfer tokenOut to msg.sender
        tokenOut(msg.sender,amountOut);

        //Update the reserves
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    //This function the user will be able to provide liquidity to the pool
    function addLiquidity(uint _amount0,uint _amount1) external returns (uint shares){

        //Pull In token0 and token1
        //Here we are transfering tokens from user to the pool
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        //Now here the users can add any amount of token0 and token1 but if they do that the price of tokens will mess up
        //Now to make sure the price of the tokens does not change 
        //Now from the math we understand for the tokens to change in price it must follow this dy/dx = y/x
        if(reserve0 > 0 || reserve1 > 0){
            require(reserve0 * _amount1 == _reserve1 * _amount0,"dy/dx != y/x");
        }


        //Mint shares
        //Now to even mint shares we measured the liquidity to be a function and that was 
        //f(x,y) = value of liquidity = sqrt(xy)
        //And we also know that we the total number of shares to mint is s = dx / x * T = dy / y * T
        if(totalSupply == 0){
            shares = _sqrt(_amount0 * _amount1);
        }else{
            shares = _min(
                (_amount0*totalSupply)/_reserve0,
                (_amount1*totalSupply)/_reserve1
            );
        }
        require(shares > 0,"Shares = 0");
        _mint(msg.sender,shares);


        //Update reserves
        _update(
            token0.transferFrom(address(this)),
            token1.transferFrom(address(this))
        );
    }

    //This function will let the users to remove liquidity
    function removeLiquidity(uint _shares) external returns(uint amount0, uint amount1){

        //We need to calculate amount0 and amount1 to withdraw 
        //As from from the math we know that to remove liquildity the amount of shares that go are 
        // dx = S / T * x;
        // dy = S / T * y;
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(amount0 > 0 && amount1 > 0 );
        
        //burn shares
        _burn(msg.sender,_shares);

        //Update the reserves
        _update(
            bal0 - amount0,
            bal1 - amount1
        );

        //Transfer tokens to msg.sender
        token0.transfer(msg.sender,amount0);
        token1.transfer(msg.sender,amount1);


    }

    function _sqrt(uint y) private pure returns(uint z) {
        if(y > 3){
            z = y;
            uint x = y / 2 + 1;
            while(x<z){
                z = x;
                x = (y / x + x) / 2;
            }
        }else if(y != 0 ){
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns(uint){
        return x <= y ? x : y;
    }
}