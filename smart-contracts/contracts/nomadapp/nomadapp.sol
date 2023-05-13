// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract nomadapp {

    uint public money_to_change;
    address payable public nomada;
    address payable public cash_provider;
    uint start_time;
    uint end_time;


    enum state {
        created, locked, release, inactive
    }    

    state public contract_status;

    constructor() payable {
        nomada = payable(msg.sender);
        contract_status = state.created;
        money_to_change = msg.value;
        start_time = block.timestamp;
        end_time = start_time + 60;
    }

    /// The function cannot be called at the current state.
    error invalid_state();

    /// Only the cash provider can call this function
    error just_cash_provider();

    /// Only the nomada can call this function
    error just_nomada();

    modifier only_nomada() {
        if(msg.sender != nomada){
            revert just_nomada();
        }
        _;
    }

    modifier only_cash_provider() {
        if(msg.sender == nomada){
            revert just_cash_provider();
        }
        _;
    }

    modifier in_state( state _state){
        if(contract_status == _state){
            revert invalid_state();
        }

        _;
    }

    modifier time_over(){
        require(block.timestamp <= end_time, "The time is over");
        _;
    }


    function cash_provider_confirm_transaction() external in_state(state.locked) only_cash_provider time_over() payable {
        
        require(msg.value == money_to_change, "Please send the same amount that the nomada, to do change");
        
        cash_provider = payable(msg.sender);
        
        contract_status = state.locked;
    }

    function confirm_received() external only_cash_provider() in_state(state.release) time_over() {
        // this funtion returns the deposit that 
        // the cash_provider made to have a colateral
        cash_provider.transfer(2 * money_to_change);
        contract_status = state.release;
    }


    function abort() external {

        require(block.timestamp >= end_time, "The transaction still has time to finish");


        if(contract_status == state.locked){
            nomada.transfer(address(this).balance/2);
            cash_provider.transfer(address(this).balance/2);
        }
        if(contract_status == state.created){
            nomada.transfer(address(this).balance);
        }
        contract_status = state.inactive;
        
    }

        function get_time_left() public view time_over returns(uint256){
        return end_time - block.timestamp;
    }

}
