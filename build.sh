#!/bin/bash

launch_gananche() {

	echo -n "* Launching eth client(ganache-cli)... "
	bash ./scripts/launch_ganache.sh
	echo "done"

	# Wait.
	sleep 1
}

create_environment() {

	echo -n "* Creating build environment.. "

	# Delete build folder.
	if [ -d "./build/" ]; then
	   rm -r ./build/
	fi

	if [ -d "../okdkjs/lib/contracts/" ]; then
	   rm -r ../okdkjs/lib/contracts/
	fi
	mkdir ../okdkjs/lib/contracts/

	if [ -d "../okdkjs-ico/assets/contracts/" ]; then
	   rm -r ../okdkjs-ico/assets/contracts/
	fi
	mkdir ../okdkjs-ico/assets/contracts/

	echo "done"
}

truffle_migrate() {
	echo "* Truffle migrate... "

	# Build and deploy to vm.
	truffle migrate --network $1

	echo "done"
}

copy_files() {
	echo -n "* Copying files to okdkjs... "
	# Copy json abi files to okdkjs.
	# find ./build/contracts/ ! -name Migrations.json -exec cp -t ../okdkjs/lib/contracts/ {} +
	rsync -r --exclude='Migrations.json' --exclude='Test.json' ./build/contracts/ ../okdkjs/lib/contracts/
	echo "done"

	echo -n "* Copying files to okdkjs-ico... "
	rsync -r --exclude='Migrations.json' --exclude='Test.json' ./build/contracts/ ../okdkjs-ico/assets/contracts/
	echo "done"
}

if [[ $1 == "local" ]]; then
	create_environment
	launch_gananche
	truffle_migrate development
	copy_files

elif [[ $1 == "ropsten" ]]; then
	create_environment
	truffle_migrate ropsten
	copy_files

else
	echo "Wrong argument. Run ./build.sh local or ./build.sh ropsten"
	exit 
fi