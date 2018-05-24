import "./Whitelist.sol";

pragma solidity ^0.4.19;

/**
 * @title Referral
 * @dev Store referral information between ids.
 */
contract Referral {

		/* Creator of this ICO contract. */
		address owner;

		/* Admin of this ICO contract. */
		address admin;

		/* Add list of contracts that can access this contract. */
		mapping (address => bool) private systemAccess;

		/* User id to address that provided the referral link for an address. */
		mapping (bytes32 => bytes32) public referrerOf;

		Whitelist private whitelist;

		/**
		 * @dev Reverts if not in owner status.   
		 */
		modifier onlyOwner() {
			require(owner != address(0));
			require(msg.sender == owner);
			_;
		}

		/**
		 * @dev Reverts if not in admin status.  
		 */
		modifier system() {
			require(systemAccess[msg.sender]);
			_;
		}
		
		/**
		 * @dev Constructor, takes all necessary arguments.
		 * @param _whitelist Address of whitelist contract
		 */
		function Referral(Whitelist _whitelist) public {
			owner = msg.sender;
			whitelist = _whitelist;
			systemAccess[msg.sender] = true;
		}

		/**
		 * @dev Sets access level of an address. 
		 * @param _address Address to set permissions to access referral
		 * @param _hasAccess Whether the address has access
		 */
		function setSystemAccess(address _address, bool _hasAccess) onlyOwner public {
			systemAccess[_address] = _hasAccess;
		}

    /**
     * @dev Get access level of an address. 
     * @return Whether address has access
     */
    function getSystemAccess(address _address) public view returns (bool) {
      return systemAccess[_address];
    }

		/**
		 * @dev Add a referrer of an address.
		 * @param _referee Id of person who clicked the link
		 * @param _referrer Id of provider of referral link
		 */
		function addReferrer(bytes32 _referee, bytes32 _referrer) 
			system public {
		 
			require(whitelist.idInWhitelist(_referee));
			require(whitelist.idInWhitelist(_referrer));

			referrerOf[_referee] = _referrer;
		}

		/**
		 * @dev Checks whether an id has a referrer. 
		 * @param _id Id of user.
		 * @return Whether the id has a referrer.
		 * @return Id of the referrer.
		 */
		function hasReferrer(bytes32 _id) public view 
			returns (bool, bytes32) {

			return _hasReferrer(_id);
		}

		/**
		 * @dev Check if a sale is eligible for referral bonus.
		 * @param _id Id that sent ether
		 * @return _eligible True if eligible
		 * @return _referrer Id of referrer
		 */
		function _hasReferrer(bytes32 _id) 
			internal view returns (bool _eligible, bytes32 _referrer) {

			require(_id != 0x0);

			_eligible = false;
			_referrer = referrerOf[_id];

			if (_referrer != 0x0) {
				_eligible = true;
			}
		}
}