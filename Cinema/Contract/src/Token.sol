// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./Tools/IsAdmin.sol";

contract Token is ERC20 {

    IsAdmin private isAdmin;

    event WithdrawEth(address indexed to,uint amount,bool success);

    modifier adminOnly {
        require(isAdmin.isAdmin(msg.sender),"contract:::NFTDemo::NFTDemo:Admin Only.");
        _;
    }

    constructor(string memory _name,string memory _symbol,address _IsAdmin) ERC20(_name,_symbol) {
        isAdmin = IsAdmin(_IsAdmin);
    }

    function mint(address account,uint256 value) adminOnly external {
        _mint(account, value);
    }

    function burn(address account,uint256 value) adminOnly external {
        _burn(account, value);
    }

    function buy() external payable{
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint _amount,address payable _to) adminOnly external {
        (bool success,) = _to.call{value: _amount}("");
        emit WithdrawEth(_to, _amount, success);
        require(success, "Transfer Failed");
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    receive() external payable{
        _mint(msg.sender, msg.value);
    }
}