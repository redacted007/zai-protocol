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

import "./Dollar.sol";
import "./IDollar.sol";

contract ZaiV2 is Dollar {
    // 100:1 ZAI for ZAIv2
    uint256 public constant SWAP_EXCHANGE_RATE = 100;

    // Total supply of ZAI at the time of reset. Cannot swap more than that
    uint256 public constant MAX_ZAI_SWAPPABLE = 395407172763503943977588203;

    // Track zai that has been swapped
    uint256 public oldZaiSwapped = 0;

    // Original ZAI token address must be this on mainnet.
    // address(0x9d1233cc46795E94029fDA81aAaDc1455D510f15);
    // Only settable in the constructor for testing
    IDollar internal _oldZai;

    event BurnAndSwap(
        address indexed operator,
        address indexed from,
        uint256 burnAmount,
        uint256 mintAmount
    );

    constructor(address oldZaiAddress) public Dollar() {
        _oldZai = IDollar(oldZaiAddress);
    }

    // Approve the amount of ZAI for the ZAIv2 contract to burn and swap, then
    // call burnAndSwap for the address.
    function burnAndSwap(address from) public {
        uint256 burnAmount = _oldZai.allowance(from, address(this));
        require(burnAmount > 0, "gotta burn if you wanna earn...");

        oldZaiSwapped = oldZaiSwapped.add(burnAmount);
        require(
            oldZaiSwapped <= MAX_ZAI_SWAPPABLE,
            "where did all that ZAI come from..."
        );

        uint256 mintAmount = burnAmount.div(SWAP_EXCHANGE_RATE);
        require(mintAmount > 0, "how you gonna mint 0 of something?");

        _oldZai.transferFrom(from, address(this), burnAmount);
        _oldZai.burn(burnAmount);

        _mint(from, mintAmount);

        emit BurnAndSwap(msg.sender, from, burnAmount, mintAmount);
    }
}
