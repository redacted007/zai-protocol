/*
    Copyright 2020 Zero Collateral Devs, standing on the shoulders of the Empty Set Squad <zaifinance@protonmail.com>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../external/Decimal.sol";
import "../token/ZaiV2.sol";
import "../oracle/Oracle.sol";
import "../oracle/Pool.sol";
import "./Upgradeable.sol";
import "./Permission.sol";

contract Deployer1 is State, Permission, Upgradeable {
    // Original ZAI token address must be this on mainnet
    address public constant OLD_ZAI_ADDRESS =
        address(0x9d1233cc46795E94029fDA81aAaDc1455D510f15);

    function initialize() public initializer {
        _state.provider.dollar = new ZaiV2(OLD_ZAI_ADDRESS);
    }

    function implement(address implementation) external {
        upgradeTo(implementation);
    }
}

contract Deployer2 is State, Permission, Upgradeable {
    function initialize() public initializer {
        _state.provider.oracle = new Oracle(address(dollar()));
        oracle().setup();
    }

    function implement(address implementation) external {
        upgradeTo(implementation);
    }
}

contract Deployer3 is State, Permission, Upgradeable {
    function initialize() public initializer {
        _state.provider.pool = address(
            new Pool(address(dollar()), address(oracle().pair()))
        );
    }

    function implement(address implementation) external {
        upgradeTo(implementation);
    }
}
