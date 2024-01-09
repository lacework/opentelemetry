#!/bin/bash
if [[ -z "$lwKeyId" || -z "$lwSecret" || -z "$lwAccount" ]]; then
    echo "lwKeyId, lwSedret and lwAccount must be set to run test."
    exit 1
fi

echo Testing
(
    export lwDataDirectory="/tmp/helloworldtest"
    export lwMetricsEndpoint="http://localhost:4318"
    source ../shared/start.sh helloworld.sh
)
