// SPDX-License-Identifier: GPL-3.0 

pragma solidity >=0.5.0 <0.9.0;

//This is code to a fully-ERC20-compliant function which has 6 functions and 2 events
interface ERC20Interface{
    //Not all 6 functions are mandotary but the first 3 functions are mandotoary
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns(uint balance);
    function transfer(address to,uint tokens) external returns (bool success);

    function allowance(address tokenOwner,address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}