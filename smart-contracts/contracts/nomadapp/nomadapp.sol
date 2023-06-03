// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract nomadapp {

    enum State {
        created, locked, release, inactive
    }

    struct Exchange {
        uint money_to_change;
        address payable nomada;
        State contract_status;
        uint start_time;
        uint end_time;
    }

    bytes32[] private password1;
    
    address payable cash_provider;

    Exchange[] public exchanges;

        
    function start_new_exchange(bytes32 _password_hashed) public payable  {
        
        uint _start_time = block.timestamp;
        uint _end_time = _start_time + 1 * 8 hours;
        

        Exchange memory exchange = Exchange(msg.value, payable(msg.sender), State.created, _start_time, _end_time);
        exchanges.push(exchange);
        password1.push(_password_hashed);
    }

    /// The function cannot be called at the current state.
    error invalid_state();

    /// Only the cash provider can call this function
    error just_cash_provider();

    /// Only the nomada can call this function
    error just_nomada();

    /// Time is Over
    error _time_over();

    modifier only_nomada(uint exchande_index) {
        if(msg.sender != exchanges[exchande_index].nomada){
            revert just_nomada();
        }
        _;
    }

    modifier only_cash_provider(uint exchande_index) {
        if(msg.sender == exchanges[exchande_index].nomada){
            revert just_cash_provider();
        }
        _;
    }

    modifier in_state(uint exchande_index, State _state){
        if(exchanges[exchande_index].contract_status == _state){
            revert invalid_state();
        }

        _;
    }

    modifier time_over(uint exchande_index){
        if(block.timestamp >= exchanges[exchande_index].end_time){
           if(exchanges[exchande_index].contract_status == State.locked){
                exchanges[exchande_index].nomada.transfer(address(this).balance/2);
                cash_provider.transfer(address(this).balance);
                revert _time_over();
            }
            if(exchanges[exchande_index].contract_status == State.created){
                exchanges[exchande_index].nomada.transfer(address(this).balance);
                revert _time_over();
            } 
        }
        _;
    }


    function cash_provider_confirm_transaction(uint exchande_index) external in_state(exchande_index, State.locked) only_cash_provider(exchande_index) time_over(exchande_index) payable {
        
        require(msg.value == exchanges[exchande_index].money_to_change, "Please send the same amount that the nomada, to do change");
        
        cash_provider = payable(msg.sender);
        
        exchanges[exchande_index].contract_status = State.locked;
    }

    function confirm_received(string memory _password, uint exchande_index) external only_cash_provider(exchande_index) in_state(exchande_index, State.release) time_over(exchande_index) {
        // this funtion returns the deposit that 
        // the cash_provider made to have a colateral
        bytes32 _password_ = get_password_hash(_password);
        require( password1[exchande_index] == _password_, "wrong password");

        cash_provider.transfer(address(this).balance);
        exchanges[exchande_index].contract_status = State.release;
    }


    function abort(uint exchande_index) external {

        require(block.timestamp >= exchanges[exchande_index].end_time, "The transaction still has time to finish");


        if(exchanges[exchande_index].contract_status == State.locked){
            exchanges[exchande_index].nomada.transfer(address(this).balance/2);
            cash_provider.transfer(address(this).balance);
        }
        if(exchanges[exchande_index].contract_status == State.created){
            exchanges[exchande_index].nomada.transfer(address(this).balance);
        }
        exchanges[exchande_index].contract_status = State.inactive;
        
    }

    function get_time_left(uint exchande_index) public view returns(uint256){
        require(block.timestamp <= exchanges[exchande_index].end_time, "The time is over");
        return exchanges[exchande_index].end_time - block.timestamp;

    }
    

    function get_balance() public view returns(uint real_balance) {
        real_balance = address(this).balance;
            
    } 

    function get_password_hash(string memory _password) private pure returns (bytes32){
        return keccak256(abi.encodePacked(_password));
    }


}
    