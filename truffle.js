const HDWalletProvider = require('truffle-hdwallet-provider');
var mnemonic = "";

module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8546,
            network_id: "*", // Match any network id.
            from: "0x929FFF0071a12d66b9d2A90f8c3A6699551E91e3"
        },  
	    ropsten: {
	      provider: function() {
        	return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/ynXBPNoUYJ3C4ZDzqjga")
      	  },
      	  network_id: 3
	    }
    }
 };
