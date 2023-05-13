// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract timer{

    uint _start;
    uint _end;  

    modifier time_over(){
        require(block.timestamp <= _end, "The time is over");
        _;
    }

    function start() public {
        _start = block.timestamp;
    }

    function end(uint total_time) public {
        _end = total_time + _start;
    }

    function get_time_left() public view time_over returns(uint256){
        return _end - block.timestamp;
    } 
}   