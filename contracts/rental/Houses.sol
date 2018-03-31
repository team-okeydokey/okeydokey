pragma solidity ^0.4.19;

import "../core/OkeyDokey.sol";
import "./Devices.sol";

contract Houses {

    /** Admin of this contract. */
    address private admin;

    /** Running count of house ids. Smallest valid house index is 1. */
    uint256 houseId = 0;

    /** Map of house ids to each corresponding house. */
    mapping(uint256 => House) private houses;

    /** Map of addresses to ids of houses it owns. */
    mapping(address => uint256[]) private housesOf;

    /** Map of a grid's id to houses located in that particular grid. */
    mapping(uint256 => uint256[]) private housesInGrid;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Address of Devices contract. */
    address private devicesAddress;

    /** Instance of Devices contract. */
    Devices private devices;

    /** Structure of a house. */
    struct House {

        /* House info */
        uint256 id;
        bytes bzzHash;

        /* Owner info */
        address host;
        address[] administrators;

        /* Smart devices */
        address[] devices;

        /* Location */
        uint256 gridId;

        /* Prices */
        uint256 hourlyRate;
        uint256 dailyRate;
        uint256 utilityFee;
        uint256 cleaningFee;

        /* Logistics */
        bool active;
        bool valid;
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
    modifier onlyHost(uint256 id) {

        require(0 < id && id <= houseId);
        require(houses[id].valid);

        /* Verify owner. */
        require(houses[id].host == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house admins can run.
     * 
     * @param id The id of house being manipulated.
     */
    modifier onlyAdmins(uint256 id) {

        require(0 < id && id <= houseId);
        require(houses[id].valid);
        
        /* Search for admin address. */
        bool found = false;
        address[] storage admins = houses[id].administrators;
        for (uint256 i=0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                found = true;
            }
        }

        require(found);

        _;
    }

    /**
     * Modifier for checking valid house.
     *
     * @param id The id of house to check.
     */
    modifier validHouse(uint256 id) {
        require(0 < id && id <= houseId);

        House storage house = houses[id]; 

        require(house.valid);  

        _;
    }

    /**
     * Broadcast registration of new house.
     *
     * @param id Id of the new house.
     */
     event NewHouse(uint256 id);

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
     */
    function initializeContracts(address _okeyDokeyAddress)
        OkeyDokeyAdmin public returns (bool success) {
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        devicesAddress = okeyDokey.getAddress(2);
        devices = Devices(devicesAddress);
    }

    /**
     * Register and list a new house.
     *
     * @param bzzHash Swarm identifier of JSON file containing house info.
     * @param gridId Id within the Earth's grid.
     * @param hourlyRate Hourly fee in KEY tokens.
     * @param dailyRate Daily fee in KEY tokens.
     * @param utilityFee Utility fee in KEY tokens.
     * @param cleaningFee Cleaning fee in KEY tokens.
     * @return success Whether the registration was successful.
     */
    function registerHouse(bytes bzzHash, uint256 gridId, 
                           uint256 hourlyRate, uint256 dailyRate, 
                           uint256 utilityFee, uint256 cleaningFee) public {

        // TODO: more contraints
        // ex: require(bzzHash.length != 0);

        /* Smallest houseId is 1 */
        houseId += 1;

        House memory house;

        house.id = houseId;
        house.bzzHash = bzzHash;

        house.host = msg.sender;
        house.gridId = gridId;

        /* Logistics */
        house.active = true;
        house.valid = true;

        /* Prices */
        house.hourlyRate = hourlyRate;
        house.dailyRate = dailyRate;
        house.utilityFee = utilityFee;
        house.cleaningFee = cleaningFee;

        /* Save newly created house to storage. */
        houses[house.id] = house;
        housesOf[msg.sender].push(house.id);
        housesInGrid[gridId].push(house.id);

        /* Add host as administrator as well */
        houses[house.id].administrators.push(msg.sender);

        NewHouse(houseId);
    } 
    
    /**
     * Edit a listed house.
     *
     * @param id The id of the house to edit.
     * @param bzzHash Swarm identifier of JSON file containing house info.
     * @param gridId Id within the Earth's grid.
     */
    function editHouse(uint256 id, bytes bzzHash, uint256 gridId) onlyAdmins(id) public {

        House storage house = houses[id]; 

        house.bzzHash = bzzHash;

        /* If gridId is different from the previous one, update gridId */
        if(house.gridId != gridId) {
            /* Remove house from previous grid group */
            removeFromGrid(house.gridId, house.id);

            /* Add house to new grid group. */
            housesInGrid[gridId].push(house.id);

            /* Update location. */
            house.gridId = gridId;

            return;
        }
    }

    /**
     * Remove houseId from grid.
     *
     * Helper function for editHouse. 
     *
     * @param prevGridId The id of the grid to erase house from.
     * @param id The id of the house to erase.
     * @return success Whether the operation was successful.
     */
    function removeFromGrid(uint256 prevGridId, uint256 id) internal {

        uint256[] storage houseIds = housesInGrid[prevGridId];
        uint256 toErase;
        for (uint256 i=0; i < houseIds.length; i++) {
            if (houseIds[i] == id) {
                toErase = i;
            }
        }

        /* Double check if there exists house id in grid group */        
        require(toErase != houseIds.length);

        // TODO: currently, this leaves a gap (deleting simply makes element 0)
        delete houseIds[toErase];
    }

    /**
     * Add administrator to house.
     *
     * @param id Id of house to edit.
     * @param newAdmin The address of new admin.
     */
    function addAdministrator(uint256 id, address newAdmin) onlyHost(id) public {

        House storage house = houses[id];

        if (house.valid) {
            bool found = false;
            uint256 index = 0;
            address[] storage admins = house.administrators;

            /* Search for previous entry */
            for (uint256 i=0; i < admins.length; i++) {
                if (admins[i] == newAdmin) {
                    found = true;
                    index = i;
                }
            }

            if (!found) {
                house.administrators.push(newAdmin);
                return;
            }
        }
    }

    /**
     * Remove administrator from house.
     *
     * @param id Id of house to query.
     * @param toDelete The address of admin to delete.
     */
    function removeAdministrator(uint256 id, address toDelete) onlyHost(id) public {

        House storage house = houses[id];

        if (house.valid) {

            bool found = false;
            uint256 index = 0;
            address[] storage admins = house.administrators;

            /* Search for previous entry */
            for (uint256 i=0; i < admins.length; i++) {
                if (admins[i] == toDelete) {
                    found = true;
                    index = i;
                }
            }

            if (found) {
                // TODO: currently, this leaves a gap (deleting simply makes element 0)
                delete admins[index];
                return;
            }
        }
    }

    /**
     * Fetch house information.
     *
     * @param _id The id of the house to query.
     * @return success Whether the query was successful.
     * @return id Id of the house.
     * @return bzzHash Swarm identifier of JSON file containing house info.
     * @return host Address of the host.
     * @return hourlyRate Hourly fee in KEY tokens.
     * @return dailyRate Daily fee in KEY tokens.
     * @return utilityFee Utility fee in KEY tokens.
     * @return cleaningFee Cleaning fee in KEY tokens.
     * @return active Whether the listing is active.
     */
    function getHouseInfo(uint256 _id) validHouse(_id) public view
        returns (bool success, uint256 id, bytes bzzHash, 
                 address host, uint256 hourlyRate, uint256 dailyRate, 
                 uint256 utilityFee, uint256 cleaningFee, bool active) {

        success = false;

        House storage house = houses[_id]; 

        id = house.id;
        bzzHash = house.bzzHash;
        host = house.host;
        hourlyRate = house.hourlyRate;
        dailyRate = house.dailyRate;
        utilityFee = house.utilityFee;
        cleaningFee = house.cleaningFee;
        active = house.active;
        success = true;
    } 

    /**
     * Self destruct.
     */
    function kill() OkeyDokeyAdmin public { 
        selfdestruct(admin); 
    }

}