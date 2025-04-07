// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PBetting {
    enum BetStatus { Open, Accepted, Resolved, Cancelled }

    struct Bet {
        uint256 id;
        address payable creator;
        address payable acceptor;
        uint256 amount;
        string description;
        uint8 creatorPrediction;
        uint8 outcome;
        BetStatus status;
    }

    uint256 public betCounter;
    mapping(uint256 => Bet) public bets;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    event BetCreated(uint256 indexed betId, address creator, uint256 amount);
    event BetAccepted(uint256 indexed betId, address acceptor);
    event BetResolved(uint256 indexed betId, uint8 outcome);
    event BetCancelled(uint256 indexed betId);

    constructor() {
        owner = msg.sender;
    }

    function createBet(string memory _description, uint8 _prediction) external payable {
        require(msg.value > 0, "Bet amount must be greater than 0");

        betCounter++;
        bets[betCounter] = Bet({
            id: betCounter,
            creator: payable(msg.sender),
            acceptor: payable(address(0)),
            amount: msg.value,
            description: _description,
            creatorPrediction: _prediction,
            outcome: 255,
            status: BetStatus.Open
        });

        emit BetCreated(betCounter, msg.sender, msg.value);
    }

    function acceptBet(uint256 _betId) external payable {
        Bet storage bet = bets[_betId];
        require(bet.status == BetStatus.Open, "Bet not open");
        require(msg.value == bet.amount, "Bet amount mismatch");

        bet.acceptor = payable(msg.sender);
        bet.status = BetStatus.Accepted;

        emit BetAccepted(_betId, msg.sender);
    }

    function resolveBet(uint256 _betId, uint8 _actualOutcome) external onlyOwner {
        Bet storage bet = bets[_betId];
        require(bet.status == BetStatus.Accepted, "Bet must be accepted first");

        bet.outcome = _actualOutcome;
        bet.status = BetStatus.Resolved;

        if (bet.creatorPrediction == _actualOutcome) {
            bet.creator.transfer(bet.amount * 2);
        } else {
            bet.acceptor.transfer(bet.amount * 2);
        }

        emit BetResolved(_betId, _actualOutcome);
    }

    function cancelBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(msg.sender == bet.creator, "Only creator can cancel");
        require(bet.status == BetStatus.Open, "Only open bets can be cancelled");

        bet.status = BetStatus.Cancelled;
        bet.creator.transfer(bet.amount);

        emit BetCancelled(_betId);
    }

    function getBet(uint256 _betId) external view returns (Bet memory) {
        return bets[_betId];
    }
}
