# Kill running instance of vm.
pkill -f ganache-cli

# Launch vm in a new window.
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        x-terminal-emulator -e "ganache-cli --port=8546 --account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,100000000000000000000' --account='0xfd4c79eee4e36d966b38a6617f60e3bdebec184e640d1d11348ba838c9129c48,100000000000000000000'" &

elif [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'tell application "Terminal" to do script "ganache-cli --port=8546 --account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,100000000000000000000' --account='0xfd4c79eee4e36d966b38a6617f60e3bdebec184e640d1d11348ba838c9129c48,100000000000000000000'"' &

# elif [[ "$OSTYPE" == "cygwin" ]]; then

# elif [[ "$OSTYPE" == "msys" ]]; then

# elif [[ "$OSTYPE" == "win32" ]]; then

# elif [[ "$OSTYPE" == "freebsd"* ]]; then

# else
        # Unknown.
fi

# Wait.
sleep 1

# Delete build folder.
if [ -d "./build/" ]; then
   rm -r ./build/
fi

if [ -d "../okdkjs/lib/contracts/" ]; then
   rm -r ../okdkjs/lib/contracts/
fi
mkdir ../okdkjs/lib/contracts/


# Build and deploy to vm.
truffle migrate

# Copy json abi files to okdkjs.
# find ./build/contracts/ ! -name Migrations.json -exec cp -t ../okdkjs/lib/contracts/ {} +
rsync -r --exclude='Migrations.json' --exclude='Test.json' ./build/contracts/ ../okdkjs/lib/contracts/