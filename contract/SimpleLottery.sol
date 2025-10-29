// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLottery {
    address public owner;
    uint public entryFee = 0.01 ether; // cost to play
    uint public winningNumber;         // the number to guess (1–10)
    bool public isActive;

    // Mapping to store player guesses
    mapping(address => uint) public playerGuesses;

    constructor() {
        owner = msg.sender;
        isActive = true;
        _setRandomWinningNumber();
    }

    // Modifier: only owner can call
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    // Player enters a guess by paying the entry fee
    function enterGuess(uint _guess) public payable {
        require(isActive, "Game not active");
        require(msg.value == entryFee, "Must pay entry fee");
        require(_guess >= 1 && _guess <= 10, "Guess must be between 1 and 10");
        require(playerGuesses[msg.sender] == 0, "Already guessed");

        playerGuesses[msg.sender] = _guess;
    }

    // Owner reveals the winner
    function revealWinner() public onlyOwner {
        isActive = false;

        // Simple random winner check
        address winner = address(0);
        for (uint i = 0; i < _playerList.length; i++) {
            if (playerGuesses[_playerList[i]] == winningNumber) {
                winner = _playerList[i];
                break;
            }
        }

        if (winner != address(0)) {
            payable(winner).transfer(address(this).balance);
        } else {
            // If no one guessed correctly, owner keeps the funds
            payable(owner).transfer(address(this).balance);
        }
    }

    // Reset the game (only owner)
    function resetGame() public onlyOwner {
        isActive = true;
        _clearPlayers();
        _setRandomWinningNumber();
    }

    // ---- Internal utility functions ----

    address[] private _playerList;

    function _setRandomWinningNumber() internal {
        // WARNING: block data is NOT secure for randomness (use Chainlink VRF in real projects)
        winningNumber = (uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 10) + 1;
    }

    function _clearPlayers() internal {
        for (uint i = 0; i < _playerList.length; i++) {
            playerGuesses[_playerList[i]] = 0;
        }
        delete _playerList;
    }

    // track players who enter
    function _addPlayer(address player) internal {
        _playerList.push(player);
    }

    // fallback to prevent accidental ETH sends
    receive() external payable {
        revert("Use enterGuess() to play");
    }
}
