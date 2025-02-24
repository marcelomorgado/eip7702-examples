// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == address(this), "not-owner");
        _;
    }

    function sweep(address to_) external onlyOwner {
        to_.call{ value: address(this).balance }("");
    }

    receive() external payable { }
}
