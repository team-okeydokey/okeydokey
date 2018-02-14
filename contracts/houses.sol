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
     * @param id The id of house being manipulated.
     */
    modifier onlyHost(uint256 id) {
        House storage house = houses[id]; 

        require(house.valid);  

        /* Verify owner. */
        require(house.host == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house admins can run.
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyAdmins(uint256 id) {
        House storage house = houses[id]; 

        require(house.valid);  

        /* Search for admin address. */
        bool found = false;
        address[] storage admins = house.administrators;
        for (uint256 i=0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                found = true;
            }
        }

        require(found);

        _;
    }

    /**
     * Constrctor function.
     *
     * Assign contract owner (admin).
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
     * @return success Whether the registration was successful.
     * @return newId Id of the new house. Must be greater than 0 to be considered valid.
     */
    function registerHouse(bytes bzzHash, uint256 gridId) 
        public returns (bool success, uint256 newId) {

        success = false;
        newId = 0;

        /* Smallest houseId is 1 */
        houseId += 1;

        House memory house;
        house.id = houseId;
        house.host = msg.sender;

        house.bzzHash = bzzHash;

        houses[house.id] = house;

        /* Record grid. */
        bool succ = updateGridId(house.id, gridId);
        if (!succ) {
            /* This listing failed. Reset houseId. */
            houseId -= 1;
            return;
        }

        /* Logistics */
        house.active = true;
        house.valid = true;

        /* Add newly created house to storage. */
        housesOf[msg.sender].push(house.id);

        success = true;
        newId = house.id;
    } 

    /**
     * Edit a listed house.
     *
     * @param id The id of the house to edit.
     * @param bzzHash Swarm identifier of JSON file containing house info.
     * @param gridId Id within the Earth's grid.
     * @return success Whether the edit was successful.
     */
    function editHouse(uint256 id, bytes bzzHash, uint256 gridId) 
        onlyAdmins(id) public returns (bool success) {

        success = false;

        House storage house = houses[id]; 

        house.bzzHash = bzzHash;

        /* Coordinates */
        bool succ = updateGridId(id, gridId);
        if (!succ) {
            return;
        }
        
        success = true;
    } 

    /**
     * Fetch house information.
     *
     * @param _id The id of the house to query.
     * @return success Whether the query was successful.
     * @return id Id of the house.
     * @return bzzHash Swarm identifier of JSON file containing house info.
     * @return host Address of the host.
     * @return active Whether the listing is active.
     */
    function getHouseInfo(uint256 _id) public view
        returns (bool success, uint256 id, bytes bzzHash, 
                 address host, bool active) {

        success = false;

        House memory house = houses[_id]; 

        id = house.id;
        bzzHash = house.bzzHash;
        host = house.host;
        active = house.active;
        
        success = true;
    } 

    /**
     * Update coordinates for a house listing. 
     *
     * @param id The id of the house to edit.
     * @param gridId Id within the Earth's grid.
     * @return success Whether the update was successful.
     */
    function updateGridId(uint256 id, uint256 gridId) 
        internal returns (bool success) {

        success = false;

        /* Fetch previous coordinates. */
        House storage house = houses[id];  

        if (house.valid) { /* This is not a new entry. */

            /* Same as previous entry. */
            if (house.gridId == gridId) {
                return;
            } else {
                /* Erase from previous grid group */
                removeFromGrid(house.gridId, house.id);
            }
        }

        /* Add house to new grid group. */
        housesInGrid[gridId].push(house.id);

        /* Update location. */
        house.gridId = gridId;

        success = true;
     }

     /**
     * Remove houseId from grid.
     *
     * Helper function for editHouse3. 
     *
     * @param prevGridId The id of the grid to erase from.
     * @param id The id of the house to erase.
     * @return success Whether the deletion was successful.
     */
    function removeFromGrid(uint256 prevGridId, uint256 id) internal returns (bool success) {
        success = false;
        uint256[] storage ids = housesInGrid[prevGridId];
        uint256 toErase;
        for (uint256 i=0; i < ids.length; i++) {
            if (ids[i] == id) {
                toErase = i;
            }
        } 
        delete ids[toErase];
        success = true;
    }

    /**
     * Add administrator to house.
     *
     * @param id Id of house to edit.
     * @param newAdmin The address of new admin.
     * @return success Whether the operation was successful.
     */
    function addAdministrator(uint256 id, address newAdmin) 
        onlyHost(id) public returns (bool success) {

        success = false;

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
                success = true;
                return;
            }
        }

    }

    /**
     * Remove administrator from house.
     *
     * @param id Id of house to query.
     * @param toDelete The address of admin to delete.
     * @return success Whether the operation was successful.
     */
    function removeAdministrator(uint256 id, address toDelete) 
        onlyHost(id) public returns (bool success) {

        success = false;

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
                delete admins[index];
                success = true;
                return;
            }
        }
    }

    /**
     * Getter for Swarm hash of house.
     *
     * @param id Id of house to query.
     * @return success Whether the query was successful.
     * @return bzzHash Swarm identifier of JSON file containing house info.
     */
    function getBzzHash(uint256 id) public view returns (bool success, bytes bzzHash) {
        success = false;

        House storage house = houses[id];
        if (house.valid) {
            success = true;
            bzzHash = house.bzzHash;
            return;
        }
    }

    /**
     * Self destruct.
     */
    function kill() system public { 
        selfdestruct(admin); 
    }

}