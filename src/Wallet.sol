// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { Owned } from "./Owned.sol";

contract Wallet is Owned {
    // keccak256(abi.encode(uint256(keccak256("storage.Wallet")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StorageLocation = 0x8d58856f5d2b6218fe8ed9ff4fac0e26c678dc4dd9e19c67019979324ec8d700;

    struct Storage {
        uint256 numOfCalls;
    }

    function _getStorage() private pure returns (Storage storage $) {
        assembly {
            $.slot := StorageLocation
        }
    }

    function numOfCalls() external view returns (uint256) {
        return _getStorage().numOfCalls;
    }

    struct Call {
        bytes data;
        address to;
        uint256 value;
    }

    function execute(Call[] memory calls) external payable onlyOwner {
        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];
            (bool success, bytes memory result) = call.to.call{ value: call.value }(call.data);
            require(success, string(result));
            _getStorage().numOfCalls++;
        }
    }
}
