//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Counters.sol";
// import "./Vault.sol";
import "hardhat/console.sol";

interface IVault {
    function createVault(uint256 gameId) external payable;
    function addAmount(uint256 gameId) external payable;
    function withdraw(uint256 gameId, address payable winner) external payable;
    function claim(uint256 gameId, address payable user) external payable;
}

contract TicTacToe {
    using Counters for Counters.Counter;
    Counters.Counter private _gameId;
    address vaultAddr;

    struct Player {
        address payable addr;
        uint256 betEth;
    }

    enum GameState {
        READY,
        PLAYING,
        FINISHED,
        CANCELED
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

    function createGame() external payable {
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

        // (bool success, ) = vaultAddr.call{value: msg.value}(
        //     abi.encodeWithSignature("createVault(uint256)", gameId)
        // );
        // require(success, "Failed to createVault vault");
        
        IVault(vaultAddr).createVault{value: msg.value}(gameId);
    }

    function joinAndStartGame(uint256 gameId) external payable {
        Game storage game = games[gameId];
        require(game.user1.betEth == msg.value, "Invalid ETH");
        game.user2 = Player({addr: payable(msg.sender), betEth: msg.value});
        game.status = GameState.PLAYING;

        // (bool success, ) = vaultAddr.call{value: msg.value}(
        //     abi.encodeWithSignature("addAmount(uint256)", gameId)
        // );
        // require(success, "Failed to addAmount vault");
        IVault(vaultAddr).addAmount{value: msg.value}(gameId);
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

        //Check if the game has ended
        if (_isWinner(gameId, identifier)) {
            game.winner = msg.sender;
            game.status = GameState.FINISHED;
            //give prize to the winner
            // (bool success, ) = vaultAddr.call(
            //     abi.encodeWithSignature(
            //         "withdraw(uint256,address)",
            //         gameId,
            //         payable(game.winner)
            //     )
            // );
            // require(success, "Failed to withdraw vault");
            IVault(vaultAddr).withdraw(gameId, payable(game.winner));
        } else if (game.turnsTaken == 9) {
            //Draw
            game.status = GameState.FINISHED;
            _resetGame(game);
        }
    }

    function cancelGameAndRefund(uint256 gameId) external payable {
        Game storage game = games[gameId];
        require(game.status == GameState.READY, "Can't cancel");
        game.status = GameState.CANCELED;
        
        // (bool success, ) = vaultAddr.call(
        //         abi.encodeWithSignature(
        //             "claim(uint256,address)",
        //             gameId,
        //             payable(game.user1.addr)
        //         )
        //     );
        // require(success, "Failed to withdraw vault");
        IVault(vaultAddr).claim(gameId, payable(game.user1.addr));
    }

    function _resetGame(Game storage game) private {
        BoardState[9] memory board;
        game.turnsTaken = 0;
        game.board = board;
        game.status = GameState.PLAYING;
    }

    function _isWinner(uint256 gameId, BoardState bstate)
        private
        view
        returns (bool)
    {
        Game memory game = games[gameId];

        uint8[3][8] memory winningFilters = [
            [0, 1, 2], //rows
            [3, 4, 5],
            [6, 7, 8],
            [0, 3, 6], //columns
            [1, 4, 7],
            [2, 5, 8],
            [0, 4, 8], //diagonals
            [6, 4, 2]
        ];

        // See if either of the players have won
        for (uint8 i = 0; i < winningFilters.length; i++) {
            uint8[3] memory filter = winningFilters[i];

            // Player was successful!
            if (
                game.board[filter[0]] == bstate &&
                game.board[filter[1]] == bstate &&
                game.board[filter[2]] == bstate
            ) {
                return true;
            }
        }
        return false;
    }

    function getBoard(uint256 gameId)
        external
        view
        returns (BoardState[9] memory)
    {
        return games[gameId].board;
    }

    function getGameInfo(uint256 gameId) external view returns (Game memory) {
        return games[gameId];
    }

    function setVault(address _vaultAddr) external {
        vaultAddr = _vaultAddr;
    }

    function getVault() external view returns (address) {
        return address(vaultAddr);
    }
}
