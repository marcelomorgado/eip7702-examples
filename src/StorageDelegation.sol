pragma solidity ^0.8.20;

contract StorageDelegation {
    uint256 public counter;

    function set(uint256 c) external {
        counter = c;
    }

    function noop() external { }
}
