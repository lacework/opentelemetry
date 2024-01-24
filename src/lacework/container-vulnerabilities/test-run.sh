#!/bin/bash
if [[ -z "$lwKeyId" || -z "$lwSecret" || -z "$lwAccount" ]]; then
    echo "lwKeyId, lwSedret and lwAccount must be set to run test."
    exit 1
fi

echo Testing
(
    export lwDataDirectory="/tmp/lwcontainertestdata"
    export lwTmpWorkDirectory="/tmp/lwcontainertesttmp"
    export lwMetricsEndpoint="http://localhost:4318"
    export lwAttributeFilter="digest,fullImageName,lwUrl,activeContainers"

    export PATH=../shared:$PATH

    rm -f $lwDataDirectory/*
    rm -f $lwTmpWorkDirectory/*

    source start.sh run.sh

    echo Second run
#    source start.sh run.sh
)
