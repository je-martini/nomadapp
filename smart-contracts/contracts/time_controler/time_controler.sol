// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract time_controler{

    error not_owner_error();
    error all_ready_queued_error(bytes32 tx_id);
    error timetamp_not_in_range_error(uint block_timestamp, uint timestamp);
    error not_queued_error(bytes32 tx_id);
    error times_tamp_not_passed_error(uint block_timestamp, uint timestamp);
    error times_tamp_expired_error(uint block_times_tamp, uint expires_at);
    error tx_failed_error();
    
    event cancel(bytes32 indexed tx_id);

    event queue_(
        bytes32 indexed tx_id,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint times_tamp
    );

    event execute_(
        bytes32 indexed tx_id,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint times_tamp
    );

    uint public constant min_delay = 10;
    uint public constant max_delay = 1000;
    uint public constant grace_period = 1000;

    address public owner;
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable{}

    modifier only_owner(){
        if(msg.sender != owner){
            revert not_owner_error();
        }
        _;
    }

    function get_tx_id(address _target,
        uint _value,
        string calldata _func,
        string calldata _data,
        uint _times_tamp) public pure returns(bytes32 tx_id){
        return keccak256(
            abi.encode(
                _target, _value,_func, _data, _times_tamp
            )
        );
    }

    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _times_tamp

    ) external only_owner{
        bytes32 tx_id = get_tx_id(_target, _value, _func, _data, _times_tamp);
        if(queued[tx_id]) {
            revert all_ready_queued_error(tx_id); 
        }

        if( _times_tamp < block.timestamp + min_delay ||
            _times_tamp > block.timestamp + max_delay ){
                revert timetamp_not_in_range_error(block.timestamp, _times_tamp);
            }
        

        queued[tx_id] = true;
        
        emit queue_(
            tx_id, _target, _value, _func, _data, _times_tamp
        );  

    }
    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _times_tamp
    ) external payable only_owner() returns(bytes memory)
    {
        bytes32 tx_id = get_tx_id(_target, _value, _func, _data, _times_tamp);

        if(!queued[tx_id]){
            revert not_queued_error(tx_id);
        }

        if(block.timestamp < _times_tamp){
            revert times_tamp_not_passed_error(block.timestamp, _times_tamp);
        }

        if(block.timestamp > _times_tamp + grace_period){
            revert times_tamp_expired_error(block.timestamp, _times_tamp + grace_period);
        }

        queued[tx_id] = false;

        bytes memory data;

        if(bytes(_func).length > 0 ){
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))), _data 
            );
        }else {
            data = _data; 
        }
        (bool ok, bytes memory res) = _target.call{value: _value}(data);

            if(!ok) {
                revert tx_failed_error();
            }

            emit execute_(tx_id, _target, _value, _func, _data, _times_tamp);
            return res ;
    }

    function cancel(bytes32 _tx_id) external only_owner(){
        if (!queued[_tx_id]){
            revert not_queued_error(_tx_id);
        }

        queued[_tx_id] = false;
        emit cancel(_tx_id);
    }
}

contract try_time_controler{
    address public _time_controler;


    constructor(address _time_controler_){

        _time_controler = _time_controler_;
    }

    function test() external view {
        require(msg.sender == _time_controler, "not time controler");
    }

    function get_times_tamp() external view returns(uint) {
        return block.times_tamp + 100;
    }
}   