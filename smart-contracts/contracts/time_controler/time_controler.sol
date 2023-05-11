// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract time_controler{
    
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    error not_owner_error();

    modifier only_owner(){
        if(msg.sender != owner){
            revert not_owner_error();
        }
        _;
    }

    function queue(
        address _target,
        uint _value,
        string calldata _func,
        string calldata _data,
        uint _times_tamp

    ) external only_owner{

    }
    function execute() external {}
}

contract try_time_controler{
    address public _time_controler;


    constructor(address _time_controler_){

        _time_controler = _time_controler_;
    }

    function test() external view {
        require(msg.sender == _time_controler);
    }
}