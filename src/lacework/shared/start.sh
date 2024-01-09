#!/bin/bash
echo Starting...

echo Adding shared script directory to path
script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
echo Shared script directory: $script_dir

export PATH=$script_dir:$PATH

if [ -z "$lwKeyId" ]; then
    echo "Variable lwKeyId is not set, exiting script."
    exit 1
fi
if [ -z "$lwSecret" ]; then
    echo "Variable lwSecret is not set, exiting script."
    exit 1
fi
if [ -z "$lwAccount" ]; then
    echo "Variable lwAccount is not set, exiting script."
    exit 1
fi
if [ -z "$lwDataDirectory" ]; then
    echo "Variable lwDataDirectory is not set, exiting script."
    exit 1
fi
if [ -z "$lwMetricsEndpoint" ]; then
    echo "Variable lwMetricsEndpoint is not set, exiting script."
    exit 1
fi
if [ -z "$1" ]; then
    echo "Next script to run must be configured as argument, exiting script."
    exit 1
fi

echo lwDataDirectory: $lwDataDirectory
echo lwMetricsEndpoint: $lwMetricsEndpoint
echo lwAccount: $lwAccount


mkdir -p $lwDataDirectory

export lwBearerToken=$(curl -s --location 'https://'$lwAccount'/api/v2/access/tokens' \
                --header 'X-LW-UAKS: '$lwSecret'' \
                --header 'Content-Type: application/json' \
                --data '{"keyId": "'$lwKeyId'", "expiryTime":3600}' | jq -r '.token')

echo 'Bearer token written to $lwBearerToken'

./$1