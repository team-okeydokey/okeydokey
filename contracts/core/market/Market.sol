pragma solidity ^0.4.19;

import "../OkeyDokey.sol";
import "./TransactionDatabase.sol";
import "./ListingDatabase.sol";

contract Market {
  
  /** Instance of OkeyDokey contract. */
  OkeyDokey private okeydokey;

  /** Instance of TransactionDatabase contract. */
  TransactionDatabase private transactionDB;

  /** Instance of ListingDatabase contract. */
  ListingDatabase private listingDB;

  /**
   * Modifier for functions only smart contract admins can run.
   */
  modifier onlyAdmin() {
    require(okeydokey != address(0));
    require(okeydokey.isAdmin(msg.sender));

    _;
  }

  /**
   * Constrctor function. 
   *
   * Initialize other OKDK contracts this contract depends on.
   *
   * @param _okeydokeyAddress The address of main application contract
   * @param _listingDBAddress The address of database contract for market data
   */
  function Market(address _okeydokeyAddress, address _listingDBAddress) public {
    require(_okeydokeyAddress != address(0));
    require(_okeydokeyAddress != address(this));

    /* Initialize OkeyDokey. */
    okeydokey = OkeyDokey(_okeydokeyAddress);

    /* Initialize transaction db. */
    // address marketDBAddress = okeydokey.getAddress(okeydokey.TRANSACTION_DATABASE);
    // transactionDB = MarketDatabase(dbAddress);

    /* Initialize listing db. */
    // address dbAddress = okeydokey.getAddress(okeydokey.MARKET_DATABASE);
    // listingDB = MarketDatabase(dbAddress);
  }

  /** 
   * List item on market.
   */
  function listItem(bytes32 _id, uint _price) public {
    // db.write(_id, _price, );
  }

}