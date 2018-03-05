# OkeyDokey
Sharing economy platform powered by IoT blockchain, featuring smart contract enmbedded smart locks to enable fully automated rental experience

<p align="center">
  <img align="center" src="img/logo.png" width="532" height="184" alt="logo.png"/>
</p>

# Whitepaper
Read our [whitepaper](https://github.com/team-okeydokey/okeydokey/wiki/OKEYDOKEY-White-Paper)

# KEY Token Supply and Distribution
Learn more about our [Token Generation Event](https://github.com/team-okeydokey/okeydokey/wiki/OKEYDOKEY-Token-Generation-Event)



# Dependancies
Install truffle:
```bash
npm install -g truffle
```

Install ganache(Truffle's version of TestRPC):
```bash
npm install -g ganache-cli
```


# Usage
To build and deploy on local ganache test network:
```bash
chmod +x ./build.sh
./build.sh
```

If you encounter `The contract code couldn't be stored, please check your gas amount`, just run `./build.sh` again. This error occurs because we can't deploy abstract contracts.
