// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * OBXToken.sol — ORBEATX (OBX)
 * Final version — per whitepaper:
 *  - Token name: ORBEATX
 *  - Symbol: OBX
 *  - Fixed supply: 1,000,000,000 * 1e18
 *  - No mint/burn/pause/blacklist
 *  - Ownership renounced
 *  - Vesting & allocations fully automated
 *  - Human-readable helper functions for clarity
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OBXVesting.sol";

contract OBXToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 1e18;
    mapping(string => address) public vestings;

    event VestingCreated(string indexed name, address vesting, address beneficiary, uint256 amount);
    event DirectTransfer(string indexed name, address to, uint256 amount);

    constructor(
        address rewards,
        address team,
        address advisors,
        address growth,
        address privateSale,
        address publicSale,
        address liquidity,
        address infrastructure,
        address charity,
        uint256 vestingStart
    ) ERC20("ORBEATX", "OBX")
    Ownable(msg.sender) {
        require(vestingStart > 0, "Invalid vesting start time");

        _mint(address(this), INITIAL_SUPPLY);
        uint256 total = INITIAL_SUPPLY;

        // Allocations per whitepaper
        _createVesting("rewards", rewards, vestingStart, 0, 5 * 365 days, (total * 15) / 100);
        _createVesting("team_core", team, vestingStart, 0, 3 * 365 days, (total * 9) / 100);
        _createVesting("advisors_partners", advisors, vestingStart, 365 days, 18 * 30 days, (total * 3) / 100);
        _createVesting("ecosystem_growth", growth, vestingStart + 3 * 365 days, 0, 12 * 30 days, (total * 15) / 100);
        _createVesting("infra_tech", infrastructure, vestingStart + 2 * 365 days, 0, 24 * 30 days, (total * 10) / 100);
        _createVesting("charity_trust", charity, vestingStart, 0, 5 * 365 days, (total * 15) / 100);

        _directTransfer("private_sale", privateSale, (total * 8) / 100);
        _directTransfer("public_sale", publicSale, (total * 10) / 100);

        _lockTokens("liquidity_reserve", liquidity, (total * 15) / 100, 24 * 30 days);

        // Fully decentralized — renounce ownership
        renounceOwnership();
    }

    function _createVesting(
        string memory name,
        address wallet,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration,
        uint256 amount
    ) internal {
        OBXVesting v = new OBXVesting(IERC20(this), wallet, start, cliffDuration, duration);
        vestings[name] = address(v);
        _transfer(address(this), address(v), amount);
        emit VestingCreated(name, address(v), wallet, amount);
    }

    function _lockTokens(
        string memory name,
        address wallet,
        uint256 amount,
        uint256 lockDuration
    ) internal {
        OBXVesting v = new OBXVesting(IERC20(this), wallet, block.timestamp, lockDuration, 1);
        vestings[name] = address(v);
        _transfer(address(this), address(v), amount);
        emit VestingCreated(name, address(v), wallet, amount);
    }

    function _directTransfer(
        string memory name,
        address wallet,
        uint256 amount
    ) internal {
        _transfer(address(this), wallet, amount);
        emit DirectTransfer(name, wallet, amount);
    }

    //  Human-readable helper functions

    function totalSupplyReadable() external view returns (string memory) {
        return string(abi.encodePacked(_toStringReadable(totalSupply()), " OBX"));
    }

    function balanceOfReadable(address account) external view returns (string memory) {
        return string(abi.encodePacked(_toStringReadable(balanceOf(account)), " OBX"));
    }

    function vestingOverview(string memory name) external view returns (
        string memory category,
        address vestingAddress,
        address beneficiary,
        string memory total,
        string memory released,
        string memory remaining,
        string memory durationYears
    ) {
        category = name;
        vestingAddress = vestings[name];
        if (vestingAddress == address(0)) return ("", address(0), address(0), "0 OBX", "0 OBX", "0 OBX", "0 years");
        OBXVesting v = OBXVesting(vestingAddress);
        uint256 totalTokens = balanceOf(vestingAddress) + v.released();
        uint256 remainingTokens = totalTokens > v.released() ? totalTokens - v.released() : 0;
        total = string(abi.encodePacked(_toStringReadable(totalTokens), " OBX"));
        released = string(abi.encodePacked(_toStringReadable(v.released()), " OBX"));
        remaining = string(abi.encodePacked(_toStringReadable(remainingTokens), " OBX"));
        durationYears = string(abi.encodePacked(_uintToString(v.duration() / 365 days), " years"));
        beneficiary = v.beneficiary();
    }

    function _toStringReadable(uint256 value) internal pure returns (string memory) {
        uint256 integerPart = value / 1e18;
        uint256 decimalPart = (value % 1e18) / 1e14;
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