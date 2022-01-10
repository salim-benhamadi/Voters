//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// IERC-20 contract 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CeloElection {
  // SafeMath for safe integer operations
  using SafeMath for uint256;

  // List of all the elections
  Election[] private elections;

  // event for when new election starts
  event electionStarted(
    address contractAddress,
    address electionCreator,
    uint electionId,
    string title,
    string description,
    string imageLink,
    uint256 electionDeadline,
    uint256 VotersCount,  
    uint candidatesCount
  );

  function startElection(
    IERC20 cUSDToken,
    uint electionId,
    string calldata title, 
    string calldata description,
    string calldata imageLink,
    uint durationInHours,
    uint votersCount,  
    uint candidatesCount
  ) external {
    uint raiseUntil = block.timestamp.add(durationInHours.mul(1 hours));
    
    Election newElection = new Election(cUSDToken, payable(msg.sender), electionId, title, description, imageLink, raiseUntil );
    elections.push(newElection);
    
    emit electionStarted(
      address(newElection),
      msg.sender,
      electionId,
      title,
      description,
      imageLink,
      raiseUntil,
      votersCount,
      candidatesCount
    );
  }

  function returnElections() external view returns(Election[] memory) {
    return elections;
  }

}

contract Election {
  using SafeMath for uint256;
  // in order to keep track of a Election's current state
  enum ElectionState { 
    Voting,
    Canceled,
    Successful
  }
  struct Candidate {
      uint id;
      uint electionId;
      string name;
      uint voteCount;
    }
  
  IERC20 private cUSDToken;
    
  // Initialize public variables
  address payable public creator;
  uint public electionId;
  uint256 public VotersCount;    // the total number of voter
  uint public candidatesCount;   // the number of candidates
  uint public electionDeadline;
  string public title;
  string public description;
  string public imageLink;

  //List of all the candidates
  // Candidate[] private candidates;

  // Initialize state at fundraising
  ElectionState public state = ElectionState.Voting;  

  // Store accounts that have voted
  mapping(address => bool) public voters;
  // Read/write candidates
  mapping(uint => Candidate) public candidates;
  
  // Event when someone vote
    event votedEvent(uint indexed candidateId, uint indexed electionId);
//   event Voted(address voter, uint Candidate);

  modifier theState(ElectionState _state) {
    require(state == _state);
   _;
  }
  constructor (
    IERC20 token,
    address payable electionCreator,
    uint electionID,
    string memory electionTitle, 
    string memory electionDescription,
    string memory electionImageLink,
    uint electionDl
  ) {
    cUSDToken = token;
    creator = electionCreator;
    electionId = electionID;
    title = electionTitle; 
    description = electionDescription; 
    imageLink = electionImageLink; 
    electionDeadline = electionDl;
    candidatesCount = 0;
    VotersCount = 0;
    }

    function addCandidate (string memory name) external {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, electionId, name, 0);
        }
    function vote (uint candidateId) external theState(ElectionState.Voting) payable {

        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(candidateId > 0 && candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;
        VotersCount++;

        // update candidate vote Count
        candidates[candidateId].voteCount ++;
        
        // trigger voted event
        emit votedEvent(candidateId, electionId);

        checkIfElectionSuccessful();

    }
    function checkIfElectionSuccessful() public {
    if (block.timestamp >= electionDeadline) {
        state = ElectionState.Successful;
    }
    } 
    
}
