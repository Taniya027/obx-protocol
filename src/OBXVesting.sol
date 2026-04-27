// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * OBXVesting.sol — Linear Vesting Contract for ORBEATX (OBX)
 * Purpose:
 *   Handles all linear vesting and lock mechanisms defined in the ORBEATX Tokenomics.
 * Features:
 *   - Linear release with optional cliff
 *   - Human-readable functions (OBX units & years)
 *   - Secure claims via ReentrancyGuard
 *   - Immutable parameters for full transparency
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OBXVesting is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Immutable core parameters
    IERC20 public immutable token;          // OBX token contract
    address public immutable beneficiary;   // Receiver of vested tokens
    uint256 public immutable start;         // Vesting start timestamp
    uint256 public immutable cliff;         // Cliff end timestamp
    uint256 public immutable duration;      // Total vesting duration (seconds)
    uint256 public released;                // Total tokens released

    // Events
    event TokensReleased(uint256 amount, uint256 timestamp);

    constructor(
        IERC20 _token,
        address _beneficiary,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration
    ) {
        require(address(_token) != address(0), "Invalid token");
        require(_beneficiary != address(0), "Invalid beneficiary");

        token = _token;
        beneficiary = _beneficiary;
        start = _start;
        cliff = _start + _cliffDuration;
        duration = _duration == 0 ? 1 : _duration; // prevent div-by-zero
    }

    // Core Vesting Logic

    function vestedAmount() public view returns (uint256) {
        uint256 totalAllocation = token.balanceOf(address(this)) + released;
        if (block.timestamp < cliff) return 0;
        if (block.timestamp >= start + duration) return totalAllocation;

        uint256 timePassed = block.timestamp - start;
        return (totalAllocation * timePassed) / duration;
    }

    function releasableAmount() public view returns (uint256) {
        uint256 vested = vestedAmount();
        return vested <= released ? 0 : vested - released;
    }

    function claim() external nonReentrant {
        require(msg.sender == beneficiary, "Not beneficiary");
        uint256 amount = releasableAmount();
        require(amount > 0, "Nothing to claim");

        released += amount;
        token.safeTransfer(beneficiary, amount);
        emit TokensReleased(amount, block.timestamp);
    }

    // Human-readable helper functions

    function vestedAmountReadable() external view returns (string memory) {
        return string(abi.encodePacked(_toStringReadable(vestedAmount()), " OBX"));
    }

    function releasableAmountReadable() external view returns (string memory) {
        return string(abi.encodePacked(_toStringReadable(releasableAmount()), " OBX"));
    }

    function releasedReadable() external view returns (string memory) {
        return string(abi.encodePacked(_toStringReadable(released), " OBX"));
    }

    function totalAllocationReadable() external view returns (string memory) {
        uint256 total = token.balanceOf(address(this)) + released;
        return string(abi.encodePacked(_toStringReadable(total), " OBX"));
    }

    function durationReadable() external view returns (string memory) {
        uint256 yearsCount = duration / 365 days;
        return string(abi.encodePacked(_uintToString(yearsCount), " years"));
    }

    function cliffReadable() external view returns (string memory) {
        uint256 cliffDays = (cliff > start) ? (cliff - start) / 1 days : 0;
        uint256 yearsCount = cliffDays / 365;
        return string(abi.encodePacked(_uintToString(yearsCount), " years"));
    }

    function vestingPeriodReadable() external view returns (string memory) {
        uint256 totalYears = duration / 365 days;
        return string(abi.encodePacked(_uintToString(totalYears), " years total"));
    }

    // Internal Converters (for human-readable output)

    function _toStringReadable(uint256 value) internal pure returns (string memory) {
        uint256 integerPart = value / 1e18;
        uint256 decimalPart = (value % 1e18) / 1e14; // 4 decimals precision
        return string(abi.encodePacked(_uintToString(integerPart), ".", _uintToString(decimalPart)));
    }

    function _uintToString(uint256 v) internal pure returns (string memory str) {
        if (v == 0) return "0";
        uint256 j = v;
        uint256 length;
        while (j != 0) { length++; j /= 10; }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (v != 0) {
            k -= 1;
            bstr[k] = bytes1(uint8(48 + v % 10));
            v /= 10;
        }
        str = string(bstr);
    }
}