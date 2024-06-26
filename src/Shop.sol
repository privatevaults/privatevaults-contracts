// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/ICloneable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// @dev Cloning Shop Contract
// @author Bogdoslav
contract Shop {
    // @dev owner
    address payable public owner;
    // @dev fee for cloning
    uint public fee;
    // @dev user => contracts
    mapping (address => address[]) public userContracts;
    // @dev user => affiliate
    mapping (address => address payable) public userAffiliates;

    event Produced(address indexed source, address clone, address indexed user, address indexed affiliate, uint feePaid);
    event FeeChanged(uint fee);

    error WrongFeeValue();
    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// constructor() {}
    /// @dev This contract is proxy-compatible, so it should not have constructor, use init(..) instead
    function initShop(address payable owner_, uint fee_)
    external {
        owner = owner_;
        _setFee(fee_);
    }

    function _setFee(uint fee_)
    internal {
        fee = fee_;
        emit FeeChanged(fee_);
    }

    /**
     * @dev Set fee for cloning
     */
    function setFee(uint fee_)
    onlyOwner public {
        _setFee(fee_);
    }

    /**
     * @dev Deploy new clone contract
     * @param cloneable address of the contract to clone
     * @param initData data to init new contract
     */
    function produce(ICloneable cloneable, bytes memory initData, address payable affiliate)
    external payable returns (address clonedContract) {
        if (msg.value != fee) {
            revert WrongFeeValue();
        }

        address payable userAffiliate = userAffiliates[msg.sender];
        // if affiliate is set for the user, override affiliate parameter, to use first affiliate was set
        if (userAffiliate != address(0)) {
            affiliate = userAffiliate;
        } else if (affiliate != address(0)) {
            // store affiliate for the user's next transactions
            userAffiliates[msg.sender] = affiliate;
        }

        // transfer 50% to the the affiliate
        if (affiliate != address(0)) {
            affiliate.transfer(msg.value / 2);
        }

        // transfer the rest to the owner
        payable(owner).transfer(address(this).balance);

        address user = msg.sender;
        clonedContract = cloneable.clone(user, initData);
        // push deployed contract address to the storage
        userContracts[user].push(clonedContract);
        emit Produced(address(cloneable), clonedContract, user, affiliate, msg.value);
    }

    // ******** UI HELPER FUNCTIONS  ********


    /**
     * @dev Get all contracts deployed by the user
     */
    function getAllUserContracts(address user)
    public view returns (address[] memory) {
        return userContracts[user];
    }

    /**
     * @dev Gap for new variables to be added
     */
    uint256[32] private __gap;

}
