# Kill running instance of vm.
pkill -f ganache-cli

# Launch vm in a new window.
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        x-terminal-emulator -e "ganache-cli --account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,10000000000000000000000000000000000000000'" &

elif [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'tell application "Terminal" to do script "ganache-cli --account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,10000000000000000000000000000000000000000'"' &

# elif [[ "$OSTYPE" == "cygwin" ]]; then

# elif [[ "$OSTYPE" == "msys" ]]; then

# elif [[ "$OSTYPE" == "win32" ]]; then

# elif [[ "$OSTYPE" == "freebsd"* ]]; then

# else
        # Unknown.
fi

# Wait.
sleep 1

# Build and deploy to vm.
truffle migrate

# Copy json abi files to okdkjs.
# find ./build/contracts/ ! -name Migrations.json -exec cp -t ../okdkjs/lib/contracts/ {} +
rsync -r --exclude='Migrations.json' ./build/contracts/ ../okdkjs/lib/contracts/