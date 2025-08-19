// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Loyalty {
    mapping(string => uint256) public points;
    address public owner;

    event PointsAwarded(string indexed userId, uint256 amount);
    event PointsRedeemed(string indexed userId, uint256 amount, string barcode);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function awardPoints(string memory userId, uint256 amount) public onlyOwner {
        points[userId] += amount;
        emit PointsAwarded(userId, amount);
    }

    function checkPoints(string memory userId) public view returns (uint256) {
        return points[userId];
    }

    function redeemPoints(string memory userId) public onlyOwner returns (string memory) {
        uint256 amount = points[userId];
        require(amount > 0, "No points to redeem");

        points[userId] = 0;

        string memory barcode = generateBarcode(userId, amount);
        emit PointsRedeemed(userId, amount, barcode);
        return barcode;
    }

    function generateBarcode(string memory userId, uint256 amount) internal pure returns (string memory) {
        return string(abi.encodePacked("BAR-", userId, "-", uint2str(amount)));
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k--;
            bstr[k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // Helper function to check if user exists (has points)
    function userExists(string memory userId) public view returns (bool) {
        return points[userId] > 0;
    }
} 