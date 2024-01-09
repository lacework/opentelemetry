#!/bin/bash

if [[ -z "$lwKeyId" || -z "$lwSecret" || -z "$lwAccount" ]]; then
    echo "lwKeyId, lwSedret and lwAccount must be set to run test."
    exit 1
fi

(
    export lwDataDirectory=/tmp/testrunpaginglwapi



    export lwBearerToken=$(curl -s --location 'https://'$lwAccount'/api/v2/access/tokens' \
                    --header 'X-LW-UAKS: '$lwSecret'' \
                    --header 'Content-Type: application/json' \
                    --data '{"keyId": "'$lwKeyId'", "expiryTime":3600}' | jq -r '.token')


    echo Running empty filter
    echo Account: $lwAccount
    rowsloaded=`./runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Containers/search" "{}" | jq -c | wc -l`
    echo Loaded $rowsloaded rows with no filter

    echo Adding time filter
    echo Account: $lwAccount
    filter='{"timeFilter":{"startTime":"2024-01-08T15:52:23Z","endTime":"2024-01-08T16:44:35Z"}}'
    rowsloaded=`./runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Containers/search" "$filter" | jq -c | wc -l`
    echo Loaded $rowsloaded rows with filter
)
