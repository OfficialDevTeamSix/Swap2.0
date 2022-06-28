// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}

contract PYEGovernance{

    event ProposalSubmitted(uint proposalID);
    event Vote(uint proposalID, bool vote);

    address tokenContract;

    mapping(uint => Proposal) public proposals;

    uint currprop;

    mapping(uint => mapping(address => bool)) public voted;

    struct Proposal {
        uint votesReceived;
        uint votesNeeded;
        bool passed;
        string prop;
        address submitter;
        uint votingDeadline;
    }

    modifier onlyHolders{
        require(IERC20(tokenContract).balanceOf(msg.sender)>0, "Not an holder");
        _;
    }

    function vote(uint proposalID, bool sel) public onlyHolders {
        require(voted[proposalID][msg.sender]==false, "Already voted on prop");
        if(sel){
            proposals[proposalID].votesReceived +=1;
            emit Vote(proposalID, sel);
            if(proposals[proposalID].votesReceived>=proposals[proposalID].votesNeeded){
                proposals[proposalID].passed = true;
            }
            voted[proposalID][msg.sender]==true;
            emit Vote(proposalID , sel);
        }
        else{
            if(proposals[proposalID].votesReceived>=proposals[proposalID].votesNeeded){
                proposals[proposalID].passed = true;
            }
            voted[proposalID][msg.sender]==true;
            emit Vote(proposalID , sel);
        }

    }

    function addProposal(uint propID, uint deadline, string calldata newprop) public onlyHolders returns (uint proposalID) {

        require(propID>currprop, "prop already exists");

        uint vNeeded = IERC20(tokenContract).totalSupply()/2;
        vNeeded+=1;

        proposals[propID].votesNeeded = vNeeded;
        proposals[propID].submitter = msg.sender;
        proposals[propID].votingDeadline = deadline;
        proposals[propID].prop = newprop;

        currprop++;
        emit ProposalSubmitted(proposalID);
        return proposalID;

    }

}
