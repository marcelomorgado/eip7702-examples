// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { BatchCallDelegation } from "../src/BatchCallDelegation.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast {
        new BatchCallDelegation();
    }
}
