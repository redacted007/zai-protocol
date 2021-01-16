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

import "../oracle/Pool.sol";

contract MockPool is Pool {
    address private _dai;
    address private _dao;
    address private _dollar;
    address private _univ2;

    constructor(
        address dollar,
        address dai,
        address univ2
    ) public Pool(dollar, univ2) {
        _dai = dai;
    }

    function set(
        address dao,
        address dollar,
        address univ2
    ) external {
        _dao = dao;
        _dollar = dollar;
        _univ2 = univ2;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }

    function univ2() public view returns (IERC20) {
        return IERC20(_univ2);
    }

    function getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (reserveA, reserveB, ) = IUniswapV2Pair(address(univ2())).getReserves();
    }
}
