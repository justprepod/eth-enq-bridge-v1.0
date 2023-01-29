// SPDX-License-Identifier: MIT
// Copyright (c) 2021 TrinityLabDAO

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";

/**
 * @title Space Vault
 */
contract SpaceVault is
    IVault,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    event Withdraw(
        address indexed sender,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    address public bridge;
    address public governance;
    address public pendingGovernance;

    constructor() {
        governance = msg.sender;
    }

    /**
     * @notice Withdraw token.
     * @param token - token
     * @param to - address
     * @param amount - amount
     */
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external override nonReentrant onlyBridge {
        require(IERC20(token).balanceOf(address(this)) > amount, "Vault token balance to low");
        IERC20(token).safeTransfer(to, amount);
        emit Withdraw(msg.sender, token, to, amount);
    }

    /**
     * @notice Balance of token in vault.
     */
    function getBalance(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Removes tokens accidentally sent to this vault.
     */
    function sweep(
        address token,
        uint256 amount,
        address to
    ) external onlyGovernance {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Used to set the bridge contract that determines the position
     * ranges and calls rebalance(). Must be called after this vault is
     * deployed.
     */
    function setBridge(address _bridge) external onlyGovernance {
        bridge = _bridge;
    }

    /**
     * @notice Governance address is not updated until the new governance
     * address has called `acceptGovernance()` to accept this responsibility.
     */
    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /**
     * @notice `setGovernance()` should be called by the existing governance
     * address prior to calling this function.
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "pendingGovernance");
        governance = msg.sender;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "governance");
        _;
    }

    modifier onlyBridge {
        require(msg.sender == bridge, "bridge");
        _;
    }
}