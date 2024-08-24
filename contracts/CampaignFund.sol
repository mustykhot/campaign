// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Crowdfunding {
    
    // Campaign structure definition
    struct Campaign {
        string title;
        string description;
        address payable benefactor;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool ended;
    }
    
    // Mapping from campaign ID to Campaign struct
    mapping(uint => Campaign) public campaigns;
    uint public campaignCount;
    
    // Events
    event CampaignCreated(uint indexed campaignId, string title, string description, address benefactor, uint goal, uint deadline);
    event DonationReceived(uint indexed campaignId, address indexed donor, uint amount);
    event CampaignEnded(uint indexed campaignId, address benefactor, uint amountRaised);
    
    // Modifier to check if a campaign exists
    modifier campaignExists(uint campaignId) {
        require(campaignId < campaignCount, "Campaign does not exist");
        _;
    }
    
    // Modifier to check if the campaign deadline has not passed
    modifier beforeDeadline(uint campaignId) {
        require(block.timestamp < campaigns[campaignId].deadline, "Campaign deadline has passed");
        _;
    }
    
    // Modifier to check if the campaign has not ended
    modifier hasNotEnded(uint campaignId) {
        require(!campaigns[campaignId].ended, "Campaign has already ended");
        _;
    }
    
    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, address payable _benefactor, uint _goal, uint _duration) public {
        require(_goal > 0, "Goal must be greater than zero");
        
        uint deadline = block.timestamp + _duration;
        campaigns[campaignCount] = Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            ended: false
        });
        
        emit CampaignCreated(campaignCount, _title, _description, _benefactor, _goal, deadline);
        
        campaignCount++;
    }
    
    // Function to donate to a campaign
    function donateToCampaign(uint campaignId) public payable campaignExists(campaignId) beforeDeadline(campaignId) hasNotEnded(campaignId) {
        require(msg.value > 0, "Donation must be greater than zero");
        
        Campaign storage campaign = campaigns[campaignId];
        campaign.amountRaised += msg.value;
        
        emit DonationReceived(campaignId, msg.sender, msg.value);
    }
    
    // Function to end the campaign and transfer the funds
    function endCampaign(uint campaignId) public campaignExists(campaignId) hasNotEnded(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign deadline has not yet passed");
        
        campaign.ended = true;
        campaign.benefactor.transfer(campaign.amountRaised);
        
        emit CampaignEnded(campaignId, campaign.benefactor, campaign.amountRaised);
    }
    
    // Fallback function to prevent accidental ETH sending
    fallback() external payable {
        revert("Fallback function triggered, ETH returned");
    }

    // Function to withdraw leftover funds (Bonus: Contract Ownership)
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function withdrawLeftoverFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}