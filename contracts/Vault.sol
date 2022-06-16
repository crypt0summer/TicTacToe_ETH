//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract VaultContract is Ownable {
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

    event VaultClaim(
        uint256 gameId,
        address _to,
        uint256 totalAmount
    );

    // event JustFallback(string _str);
    // event JustReceive(string _str);

    function createVault(uint256 gameId) external payable onlyOwner {
        Vault storage vault = vaults[gameId];
        vault.winner = address(0x0);
        vault.totalAmount = msg.value;
    }

    function addAmount(uint256 gameId) external payable onlyOwner {
        vaults[gameId].totalAmount += msg.value;
    }

    function withdraw(uint256 gameId, address payable winner)
        external
        payable
        onlyOwner
    {
        Vault storage vault = vaults[gameId];

        emit VaultDistribution(gameId, winner, vault.totalAmount);
        uint256 _vault = vault.totalAmount;
        vault.totalAmount = 0;

        winner.transfer(_vault);

        vault.winner = address(0x0);
    }

    function claim(uint256 gameId, address payable user)
        external
        payable
        onlyOwner
    {
        Vault storage vault = vaults[gameId];

        emit VaultClaim(gameId, user, vault.totalAmount);
        uint256 _vault = vault.totalAmount;
        vault.totalAmount = 0;
        
        user.transfer(_vault);

    }

    function getVault(uint256 gameId) external view onlyOwner returns (Vault memory) {
        return vaults[gameId];
    }

    function setNewOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    fallback() external{
        // emit JustFallback("Fallback is called");
        console.log('fallback');

    }

    receive() external payable{
        // emit JustReceive("Receive is called");
        console.log('receive');
    }
}
