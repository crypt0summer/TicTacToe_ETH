//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract TicTacToe {
    using Counters for Counters.Counter;
    Counters.Counter private _gameId;

    struct Player {
        address payable addr;
        uint256 betEth;
    }

    enum GameState {
        READY,
        PLAYING,
        FINISHED
    }

    enum BoardState {
        EMPTY,
        USER1,
        USER2
    }

    struct Game {
        uint256 id;
        uint8 turnsTaken;
        address winner;
        address lastPlayed;
        Player user1;
        Player user2;
        GameState status;
        BoardState[9] board;
    }

    mapping(uint256 => Game) games;
    
    event LogGameId(uint256 gameId);

    function createGame() external payable returns (uint256) {
        BoardState[9] memory board;
        uint256 gameId = _gameId.current();

        games[gameId] = Game({
            id: gameId,
            turnsTaken: 0,
            winner: address(0x0),
            lastPlayed: address(0x0),
            user1: Player({addr: payable(msg.sender), betEth: msg.value}),
            user2: Player({addr: payable(address(0x0)), betEth: 0}),
            board: board,
            status: GameState.READY
        });
        _gameId.increment();
        emit LogGameId(gameId);
        
        return gameId;
    }

    function joinAndStartGame(uint256 gameId) external payable {
        Game storage game = games[gameId];
        require(game.user1.betEth == msg.value, "Invalid ETH");
        game.user2 = Player({addr: payable(msg.sender), betEth: msg.value});
    }

}
