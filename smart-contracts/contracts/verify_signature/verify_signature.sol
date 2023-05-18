// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract verify_signature{

    function verify(address _signer, string memory _password, bytes memory _sig)
        external pure returns (bool){
            bytes32 password_hash = get_password_hash(_password);
            bytes32 eth_signed_password_hash = get_eth_signed_password_hash(password_hash);
            return recover(eth_signed_password_hash, _sig) == _signer;
    }

    function get_password_hash(string memory _password) public pure returns (bytes32){
        return keccak256(abi.encodePacked(_password));
    }

    function get_eth_signed_password_hash(bytes32 _password_hash) public pure returns (bytes32){
        return keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        _password_hash));

    }

    function recover(bytes32 _eth_signed_password_hash, bytes memory _sign)
        public pure returns (address)
        {
            (bytes32 r, bytes32 s, uint8 v) = _split(_sign);
            return ecrecover(_eth_signed_password_hash, v, r, s);
    }

    function _split(bytes memory _sign) internal pure returns(bytes32 r, bytes32 s, uint8 v)
    {
        require(_sign.length == 65, " invalid signature length");

        assembly{
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0, mload(add(_sign, 96)))
        }
    }


}