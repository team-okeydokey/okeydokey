pragma solidity ^0.4.19;

contract Facilities {

    /** Admin of this contract. */
    address private admin;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of OkeyDokey contract. */
    OkeyDokey private okeyDokey;

    /** Addresses of owners to their facilities. */
    mapping (address => facilityId[]) private facilitiesOf;

    /** Facility ids to Facility instances. */
    mapping (bytes32 => Facility) private facilities;

    /** Zone ids to Zone objects. */
    mapping (bytes32 => Zone) private zones;

    /** Access ids to Access objects. */
    mapping (bytes32 => Access) private accesses;

    /** Guest address to his/her access ids. */
    mapping (address => bytes32[]) private accessesOf;

    /** Facility id to Bzz hash containing extra info. */
    mapping (bytes32 => bytes) private faciliyInfo;

    /** Definition of a facility. */
    struct Facility {
        address owner;
        bytes32 id;
        bytes32 name;
        bytes32[] zones;
    }

    /** Definition of a zone. A zone consists of multiple devices. */
    struct Zone {
        bytes32 id;
        bytes32 facilityId;
        bytes32 name;
        bytes32[] deviceIds; // Devices that belong to this zone.
    }

    /** Parameters that define a security clearance. */
    struct Access {
        bytes32 id; // Hash of guest address, facilityId, and zoneId.

        address guest; // Person that access is granted for.

        bytes32 facilityId;
        bytes32 zoneId;

        bool isTemporary; // Is this a temporary access?
        uint256 begin; // In seconds since UNIX epoch
        uint256 end; // In seconds since UNIX epoch

        bool hasLimit; // Is this a count limited access?
        uint256 limit; // Maximum number of access.
        uint256 count; // Number of times accessed.
    }

    /**
     * Constrctor function.
     *
     * Set the admin.
     */
    function Facilities() public {
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
     * Register a facility.
     *
     * @param bytes32 Name of the facility.
     * @param bzzHash Swarm hash containing extra information about the facility.
     */
    function registerFacility(bytes32 name, bytes bzzHash) public {
        require(msg.sender == ownerOf[facilityId]);

        var facilityId = sha3(msg.sender, name);

        if (hasFacilityId(msg.sender, facilityId)) {
            return;
        }

        /* Create new zone instance. */
        Facility memory facility;
        facility.id = facilityId;
        facility.name = name;

        /* Save to memory. */
        facilities[facilityId] = facility;
        facilitiesOf[msg.sender].push(facilityId);
        facilityInfo[facilityId].push(bzzHash);
    }

    /**
     * Check if a owner has facility of the same id.
     *
     * @param owner Address of the owner.
     * @param facilityId Id of the facility to check for.
     * @return hasId Whether the id is already in use.
     */
    function hasFacilityId(address owner, bytes32 facilityId) 
        internal view returns (bool hasId) {

        hasId = false;

        bytes32[] storage facilityIds = facilitiesOf[owner];

        for (uint256 i=0; i < facilityIds.length; i++) {

            if (facilityIds[i] == facilityId) {
                hasId = true;
                return;
            }
        }
    }

    /**
     * Designate a zone that actss as a unit of access.
     *
     * @param facilityId Id of the facility the zone belongs to.
     * @param bytes32 Name of the zone.
     */
    function defineZone(bytes32 facilityId, bytes32 name) public {
        require(msg.sender == ownerOf[facilityId]);

        var zoneId = sha3(facilityId, name);

        if (hasZoneId(facilityId, zoneId)) {
            return;
        }

        /* Create new zone instance. */
        Zone memory zone;
        zone.id = zoneId;
        zone.facilityId = facilityId;
        zone.name = name;

        /* Save to memory. */
        zones[zoneId] = zone;
        facilities[facilityId].zones.push(zone);
    }

    /**
     * Check if a facility has zone id.
     *
     * @param facilityId Id of the facility.
     * @param zoneId Id of the zone to check for.
     * @return hasId Whether the id is already in use.
     */
    function hasZoneId(bytes32 facilityId, bytes32 zoneId) 
        internal view returns (bool hasId) {

        require(msg.sender == ownerOf[facilityId]);

        hasId = false;

        bytes32[] storage zoneIds = facilities[facilityId].zones;

        for (uint256 i=0; i < zoneIds.length; i++) {

            if (zoneIds[i] == zoneId) {
                hasId = true;
                return;
            }
        }
    }

    /**
     * Give zone access to guest.
     *
     * @param guest Address of guest.
     * @param facilityId Id of the facility.
     * @param zoneId Id of the zone.
     * @param isTemporary Whether the access is timed.
     * @param begin Time when access starts, in seconds since UNIX epoch,
     * @param end Time when access ends, in seconds since UNIX epoch,
     * @param hasLimit Whether the access has count limit.
     * @param limit Maximum number of access.
     * @param count Number of times accessed.
     */
    function grantAccess(address guest, bytes32 zoneId, 
                         bool isTemporary, uint256 begin, int256 end, 
                         bool hasLimit, uint256 limit, uint256 count) public {

        require(msg.sender == ownerOf[facilityId]);

        var accessId = sha3(guest, facilityId, zoneId);

        /* Create new access instance. */
        Access memory access;
        access.id = accessId;
        access.guest = guest;
        access.zoneId = zoneId;
        access.isTemporary = isTemporary;
        access.begin = begin;
        access.end = end;
        access.hasLimit = hasLimit;
        access.limit = limit;
        access.count = 0;

        /* Save to memory. */
        accesses[accessId] = access;
        accessesOf[guest].push(accessId);
    }

    /**
     * Get a user's list of accesses.
     *
     * @return accessIds Array of access ids.
     */
    function getMyAccesses() public returns bytes32[] {

        return accessesOf[msg.sender];
    }

    /**
     * Get information about access from id.
     *
     * @param accessId Id of access instance.
     * @return zoneId Id of the zone.
     * @return isTemporary Whether the access is timed.
     * @return begin Time when access starts, in seconds since UNIX epoch,
     * @return end Time when access ends, in seconds since UNIX epoch,
     * @return hasLimit Whether the access has count limit.
     * @return limit Maximum number of access.
     * @return count Number of times accessed.
     */
    function getAccessInfo(bytes32 accessId) public view 
        returns (bytes32 zoneId, 
                 bool isTemporary, uint256 begin, int256 end, 
                 bool hasLimit, uint256 limit, uint256 count){

        Access storage access = accesses[accessId];

        zoneId = access.zoneId;
        isTemporary = access.isTemporary;
        begin = access.begin;
        end = access.end;
        hasLimit = access.hasLimit;
        limit = access.limit;
        count = access.count;
    }

    /**
     * Verify if supplied user address has access of zone.
     *
     * @param guest Address to check for.
     * @param zoneId Id of the zone.
     * @return hasAccess Whether the guest address has current access.
     */
    function verifyAccess(address guest, bytes32 zoneId) 
        public view returns (bool hasAccess) {

        bytes32[] storage accessIds = accesses[guest];

        hasAccess = false;

        for (uint256 i=0; i < accessIds.length; i++) {
            var access = accessIds[i];

            if (access.zoneId == zoneId) {

                /* Check time. */
                bool timeValid = !access.isTemporary || 
                                 (access.begin <= now && now <= access.end);

                /* Check access count. */
                bool limitValid = !access.hasLimit || 
                                  access.begin <= now && now <= access.end;

                if (timeValid && limitValid) {
                    hasAccess = true;
                    return;
                }
            }
        }
    }  

    /**
     * Override to define access actions.
     *
     * @param guest Address to check for.
     * @param zoneId Id of the zone.
     * @return hasAccess Whether the .
     */
    function access(address guest, bytes32 zoneId) public {

        Access storage access = accesses[accessId];
        
        if (access.hasLimit) {
            access.count += 1;
        }
    } 

    /**
     * Override to define pre access actions.
     *
     * @param guest Address to grant access to.
     * @param accessId Id of the access.
     */
    function preAccessActions(address guest, bytes32 accessId) public {

    }   

    /**
     * Override to define post access actions.
     *
     * @param guest Address to grant access to.
     * @param accessId Id of the access.
     */
    function postAccessActions(address guest, bytes32 accessId) public {

    }   

    /**
     * Self destruct.
     */
    function kill() public { 
        if (msg.sender == admin) selfdestruct(admin); 
    }

}