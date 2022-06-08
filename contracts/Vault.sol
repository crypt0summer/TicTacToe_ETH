//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract VaultContract is Ownable{
    struct Vault {
        address winner;
        uint256 totalAmount;
    }

    uint256 totalVaults;
    mapping(uint256 => Vault) vaults;
    
    event VaultDistribution(
        uint256 gameId,
        address winner,
        uint256 totalAmount
    );

    function createVault(
        uint256 gameId
    ) external payable onlyOwner {
        Vault storage vault = vaults[gameId];
        vault.winner = address(0x0);
        vault.totalAmount = msg.value;
    }

    function addAmount(uint256 gameId) external payable onlyOwner{
        vaults[gameId].totalAmount += msg.value;
    }

    function withdraw(uint256 gameId, address payable winner) external payable onlyOwner {
        Vault storage vault = vaults[gameId];
        
        emit VaultDistribution( gameId, winner, vault.totalAmount );
        winner.transfer(vault.totalAmount);

        vault.totalAmount = 0;
        vault.winner = address(0x0);
    }

    function getVault(uint256 gameId) external view returns (Vault memory) {
        return vaults[gameId];
    }

}
