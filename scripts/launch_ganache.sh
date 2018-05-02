#!/bin/bash

# Kill running instance of vm.
pkill -f ganache-cli

# Launch vm in a new window.
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        x-terminal-emulator -e "ganache-cli --port=8546 \
--account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,100000000000000000000' \
--account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,100000000000000000000' \
--account='0xfd4c79eee4e36d966b38a6617f60e3bdebec184e640d1d11348ba838c9129c48,100000000000000000000' \
--account='0x482a2e5d0948c04d6fd5978a77699de340b421aa8dc48601b0b8992f3119f3bf,100000000000000000000' \
--account='0x24c12c9fb0a06b715de71578617384f6a0be6ac281074f01bfdcad43a982387c,100000000000000000000' \
--account='0x39620277e3a10468a5f0d6686809f6416c5e775c9ee1400d7869e0fec83da864,100000000000000000000' \
--account='0xf1c8e88b4d44bc6624be9f4668de33dd4465ea81919d7c3231ccc56e6d085e1f,100000000000000000000'" &

elif [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'tell application "Terminal" to do script "ganache-cli --port=8546 --account='0x3656e131f04ddb9eaf206b2859f423c8260bdff9d7b1a071b06d405f50ed3fa0,100000000000000000000' --account='0xfd4c79eee4e36d966b38a6617f60e3bdebec184e640d1d11348ba838c9129c48,100000000000000000000'"' &

# elif [[ "$OSTYPE" == "cygwin" ]]; then

# elif [[ "$OSTYPE" == "msys" ]]; then

# elif [[ "$OSTYPE" == "win32" ]]; then

# elif [[ "$OSTYPE" == "freebsd"* ]]; then

# else
        # Unknown.
fi