pragma solidity ^0.4.19;

contract OkeyDokey {
    /** Get addresses of other contracts. */
    function getAddress(uint16) public view returns (address);
}

contract Devices {
    // function getAddress(uint16) public view returns (address);
}

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

        /* Logistics */
        bool active;
        bool valid;
    }

    /**
     * Modifier for functions only smart contract owner(admin) can run.
     */
    modifier system() {

        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house host(owner) can run.
     *
     * MUST INCLUDE validHouse modifier BEFORE INCLUDING THIS.
     * ex) function addAdministrator validHouse(id) onlyHost(id) public
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyHost(uint256 id) {

        /* Verify owner. */
        require(houses[id].host == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house admins can run.
     * 
     * MUST INCLUDE validHouse modifier BEFORE INCLUDING THIS.
     * ex) function editHouse validHouse(id) onlyAdmins(id) public
     * 
     * @param id The id of house being manipulated.
     */
    modifier onlyAdmins(uint256 id) {
        
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
    function initializeContracts(address _okeyDokeyAddress) system public returns (bool success) {
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        devicesAddress = okeyDokey.getAddress(2);
        devices = Devices(okeyDokeyAddress);

        return true;
    }

    /**
     * Register and list a new house.
     *
     * @param bzzHash Swarm identifier of JSON file containing house info.
     * @param gridId Id within the Earth's grid.
     * @return newId Id of the new house. Must be greater than 0 to be considered valid.
     */
    function registerHouse(bytes bzzHash, uint256 gridId) 
        public returns (uint256 newId) {

        // TODO: more contraints
        // ex: require(bzzHash.length != 0);
        
        newId = 0;

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

        /* save newly created house to storage. */
        houses[house.id] = house;
        housesOf[msg.sender].push(house.id);
        housesInGrid[gridId].push(house.id);

        /* add host as administrator as well */
        houses[house.id].administrators.push(msg.sender);

        newId = house.id;
    } 
    /**
     * Edit a listed house.
     *
     * @param id The id of the house to edit.
     * @param bzzHash Swarm identifier of JSON file containing house info.
     * @param gridId Id within the Earth's grid.
     */
    function editHouse(uint256 id, bytes bzzHash, uint256 gridId) 
        validHouse(id) onlyAdmins(id) public {

        House storage house = houses[id]; 

        // TODO: if we can use bytes32, we can check if bzzHash has changed
        // ex) if(house.bzzHash != bzzHash) ... 
        house.bzzHash = bzzHash;

        /* iif gridId is different from previous one, update gridId */
        if(house.gridId != gridId) {
            /* remove house from previous grid group */
            removeFromGrid(house.gridId, house.id);
    
            /* Add house to new grid group. */
            housesInGrid[gridId].push(house.id);
    
            /* Update location. */
            house.gridId = gridId;
        }
    } 

    /**
     * Fetch house information.
     *
     * @param _id The id of the house to query.
     * @return id Id of the house.
     * @return bzzHash Swarm identifier of JSON file containing house info.
     * @return host Address of the host.
     * @return active Whether the listing is active.
     */
    function getHouseInfo(uint256 _id) validHouse(id) public view
        returns (uint256 id, bytes bzzHash, 
                 address host, bool active) {

        House storage house = houses[_id]; 

        id = house.id;
        bzzHash = house.bzzHash;
        host = house.host;
        active = house.active;
    } 

     /**
     * Remove houseId from grid.
     *
     * Helper function for editHouse3. 
     *
     * @param prevGridId The id of the grid to erase house from.
     * @param id The id of the house to erase.
     */
    function removeFromGrid(uint256 prevGridId, uint256 id) internal {
        uint256[] storage houseIds = housesInGrid[prevGridId];
        uint256 toErase;
        for (uint256 i=0; i < houseIds.length; i++) {
            if (houseIds[i] == id) {
                toErase = i;
            }
        }

        /* double check if there exists house id in grid group */        
        require(toErase != houseIds.length);

        // TODO: currently, this leaves a gap (deleting simply makes element 0)
        delete houseIds[toErase];
    }

    /**
     * Add administrator to house.
     *
     * @param id Id of house to edit.
     * @param newAdmin The address of new admin.
     * @return success Whether adding was successful.
     */
    function addAdministrator(uint256 id, address newAdmin) 
        validHouse(id) onlyHost(id) public returns (bool success) {

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
                return true;
            }
        }
        return false; 
    }

    /**
     * Remove administrator from house.
     *
     * @param id Id of house to query.
     * @param toDelete The address of admin to delete.
     * @return success Whether the operation was successful.
     */
    function removeAdministrator(uint256 id, address toDelete) 
        validHouse(id) onlyHost(id) public returns (bool success) {

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
                return true;
            }
        }
        return false; 
    }

    /**
     * Getter for Swarm hash of house.
     *
     * @param id Id of house to query.
     * @return bzzHash Swarm identifier of JSON file containing house info.
     */
    function getBzzHash(uint256 id) validHouse(id) public view returns (bytes bzzHash) {

        return houses[id].bzzHash;
    }

    /**
     * Self destruct.
     */
    function kill() system public { 
        selfdestruct(admin); 
    }

}