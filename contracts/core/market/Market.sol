pragma solidity ^0.4.19;

import "../OkeyDokey.sol";
import "../MarketDatabase.sol";

contract Market {
  
  /** Admin of this contract. */
  address private admin;

  /** Instance of OkeyDokey contract. */
  OkeyDokey private okeyDokey;

  /** Instance of MarketDatabase contract. */
  MarketDatabase private db;

  /**
   * Modifier for functions only smart contract owner(admin) can run.
   */
  modifier system() {

      /* Verify admin. */
      require(okeydokey.isAdmin(msg.sender));

      _;
  }

  /**
   * Constrctor function.
   *
   * Set the admin.
   */
  function OkeyDokey() public {
      admin = msg.sender;
  }

  /**
   * Initialize other OKDK contracts this contract depends on.
   *
   * @param _okeyDokeyAddress The address of main application contract
   */
  function initializeContracts(address _okeyDokeyAddress) 
    systems public {
    require(_okeyDokeyAddress != address(0));
    require(_okeyDokeyAddress != address(this));

    okeyDokeyAddress = _okeyDokeyAddress;
    okeyDokey = OkeyDokey(okeyDokeyAddress);

    dbAddress = okeyDokey.getAddress();
    db = 
  }


  /** 
   * List item on market.
   */
  function listItem(bytes32 _id, ) public {

  }

}