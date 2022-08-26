// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "NonFungibleFacesLight.sol";

// To be considered: Just set the contract to "automated = true" if
// total supply of Ethernal Faces won't change anymore
// -> otherwise it will lead to uneven distribution of payout shares

contract EthernalPayout {
    using Counters for Counters.Counter;
    Counters.Counter private payout_interval;

    // =============================================================================
    // Initial Data
    // =============================================================================

    address public owner;
    address public ethernal_faces_contract_address = 0x29674B7feD83a3D0Ca54Bf9A6426f3f4212C8Bbb;

    uint256 public total_payout = 0;
    uint256 public last_balance = 0; //static value which can be just changed after interval increment or deposit

    uint public interval = 60 * 3; //10 Minutes -> TODO: Increase in Production
    uint public payout_window = 60 * 2; // 5 Minutes -> TODO: Increase in Production
    uint public last_timestamp;

    bool public paused = false;
    bool public automated = false;

    // =============================================================================
    // Stored Data Structure
    // =============================================================================

    // map payouts like: payouts[interval][token_id] = true
    mapping(uint256 => mapping(uint256 => bool)) public payouts;

    constructor(){
        last_timestamp = block.timestamp;
        owner = msg.sender;
    }

    // =============================================================================
    // Upkeep Functions
    // =============================================================================

    function checkUpkeep() public view returns (bool upkeepNeeded) {
        upkeepNeeded = (block.timestamp - last_timestamp) > interval;
    }

    function performUpkeep() private{
        //highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - last_timestamp) > interval ) {
            last_timestamp = block.timestamp;
            last_balance = address(this).balance + 0;
            payout_interval.increment();

            // Notify that a new interval started
            emit intervalChanged(true, automated, last_balance, block.timestamp, payout_window);
        }
    }

    // =============================================================================
    // Payout Functions
    // =============================================================================

    function getPayout(uint256[] calldata tokenIds) public allowed payable returns(uint256){

        // check if automated = true
        // if not
        // no upkeep is needed
        if (checkUpkeep() && automated){
            performUpkeep();
        }

        if (automated){
            require (isWithinPayoutWindow(), "Needs to be within payout window");
        }

        // get supply by external NFT Contract to calculate partion and
        // get current supply -> should be icremented within this function call
        // if someone had to increment the interval after performUpkeep function
        uint256 currentSupply = getTotalSupply(ethernal_faces_contract_address);
        uint256 current_interval = currentInterval();

        // counter to combine all valid NFT payouts
        // which are owned by msg.sender
        uint256 _money = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {

            // check if given TokenID is owned by msg.sender &&
            // check if there already was a payout for a given Token
            if (isOwner(tokenIds[i]) && !alreadyCreatedPayout(current_interval, tokenIds[i])){

                // store validated TokenID to avoid double
                // payouts per Token per Interval &&
                // sum up money for paypout
                payouts[current_interval][tokenIds[i]] = true;
                _money = _money + (last_balance * 80 / 100 / currentSupply); // 80% of one partion of total supply per interval
            }

        }

        // send money to msg.sender
        payable(msg.sender).transfer(_money);

        // store information about total money spent
        total_payout = total_payout + _money;

        // submit information to client
        emit moneySent(msg.sender, total_payout, _money);

        return _money;
    }

    function setPayout(uint256 current_interval, uint256 tokenId) public payable{
        payouts[current_interval][tokenId] = true;
    }

    // =============================================================================
    // Modifier
    // =============================================================================

    //check if someone is allowed to get payouts
    modifier allowed() {
        require(!paused, "contract is paused");
        require(walletHoldsNFT(msg.sender), "You don't own an Ethneral Faces NFT");
        _;
    }

    // check if within payout window while contract is
    // not acting in automated mode
    modifier withinPayoutWindow(){
        if (automated) {
            require(isWithinPayoutWindow(), "Not within Payout Window");
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    // =============================================================================
    // Events
    // =============================================================================

    event moneySent(address _to, uint256 _total_amount_payout, uint256 _total_amount_contract);

    event intervalChanged(bool _did_change, bool automated, uint256 last_timestamp, uint256 block_timestamp, uint256 payout_window);

    // =============================================================================
    // Read Data
    // =============================================================================


    function alreadyCreatedPayout(uint256 current_interval, uint256 tokenId) public view returns (bool){
        return payouts[current_interval][tokenId];
    }

    function isWithinPayoutWindow() public view returns (bool){
        return block.timestamp - last_timestamp < payout_window;
    }

    function getBlockTimestamp() public view returns (uint256){
        return block.timestamp;
    }

    function isOwner(uint256 tokenId) public view returns (bool) {
        return IERC721(ethernal_faces_contract_address).ownerOf(tokenId) == msg.sender;
    }

    function countNFTS(address _wallet) public view returns (uint256) {
        return IERC721(ethernal_faces_contract_address).balanceOf(_wallet);
    }

    function currentInterval() public view returns (uint256) {
        return payout_interval.current();
    }

    function totalPayout() public view returns (uint256) {
        return total_payout;
    }

    function walletHoldsNFT(address _wallet) public view returns (bool) {
        return IERC721(ethernal_faces_contract_address).balanceOf(_wallet) > 0;
    }

    function getTotalSupply(address _contract) public view returns (uint256) {
        NonFungibleFacesLight c = NonFungibleFacesLight(_contract);
        return c.currentSupply();
    }

    // =============================================================================
    // Admin Functions
    // =============================================================================

    function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    function setNFTContractAddress(address _contract) public onlyOwner returns (bool){
        ethernal_faces_contract_address = _contract;
        return true;
    }

    function setAutomated(bool _bool) public onlyOwner {
        last_timestamp = block.timestamp;
        payout_interval.increment();
        automated = _bool;

        // Notify that a new interval started
        emit intervalChanged(true, automated, last_balance, block.timestamp, payout_window);
    }

    function setPaused(bool _bool) public onlyOwner {
        paused = _bool;
    }

    function incrementInterval() public onlyOwner {
        payout_interval.increment();

        // Notify that a new interval started
        emit intervalChanged(true, automated, last_balance, block.timestamp, payout_window);
    }

    function setPayoutWindow(uint256 _payout_window) public onlyOwner {
        payout_window = _payout_window;
    }

    function withdraw() payable onlyOwner public {
        total_payout = total_payout + last_balance / 100 * 20;
        payable(msg.sender).transfer(last_balance / 100 * 20); // 20% for project funding
    }

    function deposit(uint256 amount) payable public {
        if (automated) {
            require(!isWithinPayoutWindow(), "Within Payout Window no deposits possible");
        }
        require(msg.value == amount);
        last_balance = address(this).balance + 0;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
