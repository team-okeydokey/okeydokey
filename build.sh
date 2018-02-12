# Kill running instance of vm.
pkill -f ganache-cli

# Launch vm in a new window.
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        x-terminal-emulator -e "ganache-cli" &
elif [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'tell application "Terminal" to do script "ganache-cli"' &
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
find ./build/contracts/ ! -name Migrations.json -exec cp -t ../okdkjs/lib/contracts/ {} +