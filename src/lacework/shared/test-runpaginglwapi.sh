#!/bin/bash

if [[ -z "$lwKeyId" || -z "$lwSecret" || -z "$lwAccount" ]]; then
    echo "lwKeyId, lwSedret and lwAccount must be set to run test."
    exit 1
fi

(
    export lwTmpWorkDirectory=/tmp/testrunpaginglwapi
    mkdir -p $lwTmpWorkDirectory
    outputFile=${lwTmpWorkDirectory}/testoutput.json

    export lwBearerToken=$(curl -s --location 'https://'$lwAccount'/api/v2/access/tokens' \
                    --header 'X-LW-UAKS: '$lwSecret'' \
                    --header 'Content-Type: application/json' \
                    --data '{"keyId": "'$lwKeyId'", "expiryTime":3600}' | jq -r '.token')


    echo Running empty filter
    echo Account: $lwAccount
    ./runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Containers/search" "{}" "${outputFile}"
    rowsloaded=`cat ${outputFile} | jq -c | wc -l`
    echo Loaded $rowsloaded rows with no filter

    echo Adding time filter
    echo Account: $lwAccount
    filter='{"timeFilter":{"startTime":"2024-01-08T15:52:23Z","endTime":"2024-01-08T16:44:35Z"}}'
    ./runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Containers/search" "$filter" "${outputFile}"
    rowsloaded=`cat ${outputFile} | jq -c | wc -l`
    echo Loaded $rowsloaded rows with no filter
)
