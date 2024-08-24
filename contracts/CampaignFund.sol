// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/**
 * @title Crowdfunding
 * @dev A contract that allows users to create and participate in crowdfunding campaigns.
 */
contract Crowdfunding {
    
    /// @notice Owner of the contract
    address public owner;
    
    /// @dev Initializes the contract setting the deployer as the initial owner.
    constructor() {
        owner = msg.sender;
    }
    
    /// @dev Modifier to restrict functions to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    /// @dev Structure to store campaign details.
    struct Campaign {
        string title;
        string description;
        address payable benefactor;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        bool ended;
    }
    
    /// @notice Mapping from campaign ID to Campaign details.
    mapping(uint256 => Campaign) public campaigns;
    
    /// @notice Total number of campaigns created.
    uint256 public campaignCount;
    
    /// @notice Mapping to keep track of donations per campaign per donor.
    mapping(uint256 => mapping(address => uint256)) public donations;
    
    /// @notice Event emitted when a new campaign is created.
    event CampaignCreated(
        uint256 indexed campaignId,
        string title,
        string description,
        address indexed benefactor,
        uint256 goal,
        uint256 deadline
    );
    
    /// @notice Event emitted when a donation is received.
    event DonationReceived(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount
    );
    
    /// @notice Event emitted when a campaign is successfully ended.
    event CampaignEnded(
        uint256 indexed campaignId,
        address indexed benefactor,
        uint256 amountRaised
    );
    
    /**
     * @notice Creates a new crowdfunding campaign.
     * @param _title The title of the campaign.
     * @param _description A brief description of the campaign.
     * @param _benefactor The address that will receive the funds.
     * @param _goal The fundraising goal in wei.
     * @param _duration The duration of the campaign in seconds.
     */
    function createCampaign(
        string calldata _title,
        string calldata _description,
        address payable _benefactor,
        uint256 _goal,
        uint256 _duration
    ) external {
        require(_goal > 0, "Goal must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");
        require(_benefactor != address(0), "Invalid benefactor address");
        
        uint256 deadline = block.timestamp + _duration;
        
        campaigns[campaignCount] = Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            ended: false
        });
        
        emit CampaignCreated(
            campaignCount,
            _title,
            _description,
            _benefactor,
            _goal,
            deadline
        );
        
        campaignCount++;
    }
    
    /**
     * @notice Allows users to donate to a specific campaign.
     * @param _campaignId The ID of the campaign to donate to.
     */
    function donateToCampaign(uint256 _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(!campaign.ended, "Campaign has already ended");
        require(msg.value > 0, "Donation must be greater than zero");
        
        campaign.amountRaised += msg.value;
        donations[_campaignId][msg.sender] += msg.value;
        
        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @notice Ends a campaign and transfers the funds to the benefactor.
     * @param _campaignId The ID of the campaign to end.
     */
    function endCampaign(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign is still ongoing");
        require(!campaign.ended, "Campaign has already ended");
        
        campaign.ended = true;
        
        uint256 amount = campaign.amountRaised;
        
        if (amount > 0) {
            (bool success, ) = campaign.benefactor.call{value: amount}("");
            require(success, "Transfer to benefactor failed");
        }
        
        emit CampaignEnded(_campaignId, campaign.benefactor, amount);
    }
    
    /**
     * @notice Allows the contract owner to withdraw any leftover funds.
     */
    function withdrawLeftoverFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @notice Receive function to accept plain Ether transfers.
     */
    receive() external payable {
        revert("Please use donateToCampaign function to donate");
    }
    
    /**
     * @notice Fallback function to handle unknown function calls.
     */
    fallback() external payable {
        revert("Invalid function call");
    }
}
