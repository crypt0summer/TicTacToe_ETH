//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract VaultContract is Ownable {
    enum TakenStatus {
        READY,
        PLAYING,
        FINISHED,
        CANCELED
    }

    struct Vault {
        address _to;
        uint256 totalAmount;
    }

    uint256 totalVaults;
    mapping(uint256 => Vault) vaults;

    event WithdrawVault(
        uint256 gameId,
        uint256 totalAmount,
        address _to,
        TakenStatus takenStatus
    );

    function createVault(uint256 gameId) external payable onlyOwner {
        Vault storage vault = vaults[gameId];
        vault._to = address(0x0);
        vault.totalAmount = msg.value;
    }

    function addAmount(uint256 gameId) external payable onlyOwner {
        vaults[gameId].totalAmount += msg.value;
    }

    function withdraw(uint256 gameId, address payable _to, uint8 gameStatus)
        external
        payable
        onlyOwner
    {
        Vault storage vault = vaults[gameId];

        emit WithdrawVault(gameId, vault.totalAmount, _to , TakenStatus(gameStatus));
        uint256 _vault = vault.totalAmount;
        vault.totalAmount = 0;
        vault._to = address(0x0);
        _to.transfer(_vault);
    }

    function getVault(uint256 gameId) external view onlyOwner returns (Vault memory) {
        return vaults[gameId];
    }

    function setNewOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

}
