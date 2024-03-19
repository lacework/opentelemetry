#!/bin/bash
if [[ -z "$lwKeyId" || -z "$lwSecret" || -z "$lwAccount" ]]; then
    echo "lwKeyId, lwSedret and lwAccount must be set to run test."
    exit 1
fi

echo Testing
(
    export lwDataDirectory="/tmp/lwhosttestdata"
    export lwTmpWorkDirectory="/tmp/lwhosttesttmp"
    export lwMetricsEndpoint="http://localhost:4318"
    export lwAttributeFilter="hostName,InstanceId,lw_InternetExposure,riskScore,lwUrl"
    export lwStoreExecutionLogs=true
    export lwStoreExecutionLogsDays=10

    export PATH=../shared:$PATH

    rm -f $lwDataDirectory/*
    rm -f $lwTmpWorkDirectory/*

    source start.sh run.sh

    echo Second run
    source start.sh run.sh
)
