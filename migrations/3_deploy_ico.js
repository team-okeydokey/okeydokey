const IterableMapping = artifacts.require('IterableMapping.sol');
const OkeyDokeySale = artifacts.require("OkeyDokeySale");

/** Deploy ico contract.
 *
 */
module.exports = async function(deployer) {

	try {

		// // Deploy library.
		// const libDeploy = await deployer.deploy(IterableMapping);

		// // Link deployed library and link to contract.
		// const link = await deployer.link(IterableMapping, OkeyDokeySale);
		// const contractDeploy = await deployer.deploy(OkeyDokeySale, 
		// 		uint256 _rate, address _admin, address _wallet, OkeyToken _token, 
  //                          uint256 _tokenCap, uint256 _bonusCap, uint256 _bonusRate,
  //                          uint256 _openingTime, uint256 _closingTime);

	} catch(error) {
			console.log(error);
	}

};