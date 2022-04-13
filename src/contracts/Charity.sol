pragma solidity ^0.5.0;

contract Charity {
    string public name;
    uint public campaignCount = 0;
    uint public contributionCount = 0;
    uint public withdrawalCount = 0;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => Contribution) public contributions;
    mapping(uint => Withdrawal) public withdrawals;

    struct Campaign {
        uint id;
        string name;
        address payable owner;
        uint target;
        uint minAmount;
        string description;
        string img;
        uint balance;
        uint createAt;
        uint endAt;
    }

    struct Contribution {
        uint id;
        address owner;
        uint campaignId;
        uint amount;
        uint createAt;
    }

    struct Withdrawal {
        uint id;
        uint campaignId;
        uint amount;
        string description;
        uint approveCount;
        bool isApprove;
        uint createAt;
        bool isWithdraw;
    }

    event CampaignCreated(
        uint id,
        string name,
        address payable owner,
        uint target,
        uint minAmount,
        string description,
        string img,
        uint balance,
        uint createAt,
        uint endAt
    );

    constructor() public {
        name = "'Charity on web 3' is deployed";
    }

    function createCampaign(string memory _name, uint _target, uint _minAmount, string memory _description, string memory _img, uint _end) public {
        //require a valid name
        require(bytes(_name).length > 0);
        
        //require a valid target
        require(_target > 0);

        //require a valid min amount
        require(_minAmount > 0);
        require(_minAmount < _target);

        //require a valid description
        require(bytes(_description).length > 0);

        //require a valid img
        require(bytes(_img).length > 0);

        //require a valid end time
        require(_end > 0);

        //increment campaign count
        campaignCount++;

        //create campaignCount
        campaigns[campaignCount] = Campaign(campaignCount, _name, msg.sender, _target, _minAmount, _description, _img, 0, now, _end);

        //trigger an event
        emit CampaignCreated(campaignCount, _name, msg.sender, _target, _minAmount, _description, _img, 0, now, _end);
    }

    function donateCampaign(address payable _deloyer, uint _id) public payable {
        Campaign storage _campaign = campaigns[_id];

        //make sure the campaign has a valid id
        require(_campaign.id > 0 && _campaign.id <= campaignCount);

        //make sure the msg.value >= minAmount
        require(msg.value >= _campaign.minAmount);

        //_campaign.contributorCount ++;
        //_campaign.contributors[_campaign.contributorCount] = Contributor(_campaign.contributorCount, msg.sender, msg.value, now);
        //add new contribution
        contributionCount++;
        contributions[contributionCount] = Contribution(contributionCount, msg.sender, _id, msg.value, now);

        //increase balance
        _campaign.balance = _campaign.balance + msg.value;
        
        //transfer coins
        _deloyer.transfer(msg.value);
    }

    function createWithdrawal(uint _id, uint _amount, string memory _description) public {
        //require id > 0
        require(_id > 0);

        Campaign storage _campaign = campaigns[_id];

        //require owner = owner
        require(_campaign.owner == msg.sender);

        //require amount <= amount
        require(_amount <= _campaign.balance && _amount > 0);

        //require a valid description
        require(bytes(_description).length > 0);

        //increse withdrawalCount
        withdrawalCount++;

        //add withdrawal
        withdrawals[withdrawalCount] = Withdrawal(withdrawalCount, _id, _amount, _description, 0, false, now, false);
    }

    function approveWithdrawal(uint _id) public {
        //require id > 0
        require(_id > 0);
        Withdrawal storage withdrawal = withdrawals[_id];

        //require sender is contributor
        bool checkContributor = false;
        uint campaignContributors = 0;
        for(uint i = 1; i <= contributionCount; i++) {
            if(contributions[i].campaignId == withdrawal.campaignId) {
                campaignContributors++;
                if(contributions[i].owner == msg.sender) {
                    checkContributor = true;
                }
            }
        }

        require(checkContributor == true);

        //increase approveCount
        withdrawal.approveCount++;

        //get half of contributors
        uint halfContributors = campaignContributors / 2;

        //update isApprove
        if(halfContributors < withdrawal.approveCount) {
            withdrawal.isApprove = true;
        }
    }

    function getWithdrawal(uint _id) public payable {
        //require id > 0
        require(_id > 0);
        Withdrawal storage withdrawal = withdrawals[_id];
        Campaign storage campaign = campaigns[withdrawal.campaignId];

        //require isApprove == true
        require(withdrawal.isApprove == true);

        //require isWithdraw == false
        require(withdrawal.isWithdraw == false);

        //update iswithdrawal
        withdrawal.isWithdraw = true;

        //transfer coins
        campaign.owner.transfer(msg.value);

        //update balance
        campaign.balance = campaign.balance - msg.value;
    }

    /*function purchaseProduct(uint _id) public payable {
        //fetch the productCount
        Product memory _product = products[_id];

        //fetch the owner
        address payable _seller = _product.owner;
        
        //make sure the product has a valid id
        require(_product.id > 0 && _product.id <= productCount);

        //require that there is enough Ether in the transaction
        require(msg.value >= _product.price);

        //require that the product has not been purchase already
        require(!_product.purchased);

        //require that the buyer is not the seller
        require(_seller != msg.sender);

        //tranfer ownership to the buyer
        _product.owner = msg.sender;

        //mark as purchased
        _product.purchased = true;

        //Update the product
        products[_id] = _product;

        //pay the seller by sending them Ether
        address(_seller).transfer(msg.value);

        //trigger an event
        emit ProductPurchased(productCount, _product.name, _product.price, msg.sender, true);
    }*/
}