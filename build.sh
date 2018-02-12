# Launch vm.
# killall node /usr/local/bin/ganache-cli
pkill -f ganache-cli
ganache-cli --defaultBalanceEther=1000 --gasLimit=4600000 &

# Wait.
sleep 1

# Build and deploy to vm.
truffle migrate

# Copy json abi files to okdkjs.
find ./build/contracts/ ! -name Migrations.json -exec cp -t ../okdkjs/lib/contracts/ {} +