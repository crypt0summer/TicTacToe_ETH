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
            turnsTaken: 0, //9가 되면 게임 끝
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
        game.status = GameState.PLAYING;
    }

    modifier checkPlayable(
        uint256 gameId,
        uint256 _x,
        uint256 _y
    ) {
        Game memory game = games[gameId];
        require(game.status == GameState.PLAYING, "Game is not playing");
        require(
            msg.sender == game.user1.addr || msg.sender == game.user2.addr,
            "Not a valid player"
        );
        require(game.lastPlayed != msg.sender, "Not your turn");
        require(0 < _x && _x < 4 && 0 < _y && _y < 4, "Wrong position");
        _;
    }

    function takeTurn(
        uint256 gameId,
        uint256 _x,
        uint256 _y
    ) external checkPlayable(gameId, _x, _y) {
        Game storage game = games[gameId];

        // Calculate the board location
        uint256 boardLocation = (_y - 1) * 3 + (_x - 1);

        require(game.board[boardLocation] == BoardState.EMPTY, "Already taken");

        // Mark that the game advanced
        game.lastPlayed = msg.sender;
        game.turnsTaken++;

        // Save game
        BoardState identifier;
        msg.sender == game.user1.addr
            ? identifier = BoardState.USER1
            : identifier = BoardState.USER2;
        game.board[boardLocation] = identifier;

        // console.log(uint(game.board[0]));
        // console.log(uint(game.board[1]));
        // console.log(uint(game.board[2]));
        // console.log(uint(game.board[3]));
        // console.log(uint(game.board[4]));
        // console.log(uint(game.board[5]));
        // console.log(uint(game.board[6]));
        // console.log(uint(game.board[7]));
        // console.log(uint(game.board[8]));

        //Check if the game has ended

        //Draw
        if (game.turnsTaken == 9) {
            //TODO check if someone won first
            game.status = GameState.FINISHED;
            _resetGame(game);
        }
    }

    function _resetGame(Game storage game) private {
        BoardState[9] memory board;
        game.turnsTaken = 0;
        game.board = board;
        game.status = GameState.PLAYING;
    }

    function getBoard(uint256 gameId)
        external
        view
        returns (BoardState[9] memory)
    {
        return games[gameId].board;
    }
}
