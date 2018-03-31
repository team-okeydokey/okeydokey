pragma solidity ^0.4.19;

import "../core/OkeyDokey.sol";
import "../core/access/Facilities.sol";
import "../core/market/Market.sol";

contract Houses is Facilities, Market {

    /** Admin of this contract. */
    address private admin;

    /** Map of house ids to each corresponding house. */
    mapping(bytes32 => House) private houses;

    /** Map of a grid's id to houses located in that particular grid. */
    mapping(uint256 => bytes32[]) private housesInGrid;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Structure of a house. */
    struct House {

        /* House info */
        bytes32 id;
        bytes32 name;
        bytes bzzHash;

        /* Location */
        uint256 gridId;
    }

    /**
     * Modifier for functions only smart contract owner(admin) can run.
     */
    modifier OkeyDokeyAdmin() {

        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier for functions only OkeyDokey smart contracts can run.
     * 
     * @param addr The address to check.
     */
    modifier system(address addr) {

        /* Verify admin. */
        require(okeyDokey.isOkeyDokeyContract(addr));

        _;
    }

    /**
     * Modifier for functions only house host(owner) can run.
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyHost(bytes32 id) {

        /* Verify owner. */
        require(facilities[id].owner == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house admins can run.
     * 
     * @param id The id of house being manipulated.
     */
    // modifier onlyAdmins(bytes32 id) {
        
    //     /* Search for admin address. */
    //     bool found = false;
    //     address[] storage admins = houses[id].administrators;
    //     for (uint256 i=0; i < admins.length; i++) {
    //         if (admins[i] == msg.sender) {
    //             found = true;
    //         }
    //     }

    //     require(found);

    //     _;
    // }

    /**
     * Broadcast registration of new house.
     *
     * @param success Whether the registration was successful.
     * @param id Id of the new house.
     */
     event NewHouse(bool success, uint256 id);

    /**
     * Constrctor function.
     *
     * Assign contract owner (admin).
     *
     */
    function Houses() public {
        admin = msg.sender;
    }

    /**
     * Initialize other OKDK contracts this contract depends on.
     *
     * @param _okeyDokeyAddress The address of main application contract.
     * @return success Whether the initialization was successful.
     */
    function initializeContracts(address _okeyDokeyAddress) 
        OkeyDokeyAdmin public returns (bool success) {
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        return true;
    }

    /**
     * Register and list a new house.
     *
     * @param name Name of listing. Hashes into id.
     * @param bzzHash Swarm identifier of JSON file containing house info.
     * @param gridId Id within the Earth's grid.
     */
    function registerHouse(bytes32 name, bytes bzzHash, uint256 gridId) public {

        House memory house;

        registerFacility(name, bzzHash);
        // registerItem(name, bzzHash);

        house.id = keccak256(msg.sender, name);
        house.bzzHash = bzzHash;
        house.gridId = gridId;

        /* Save newly created house to storage. */
        houses[house.id] = house;
        housesInGrid[gridId].push(house.id);
    } 

    /**
     * Self destruct.
     */
    function kill() OkeyDokeyAdmin public { 
        selfdestruct(admin); 
    }

}