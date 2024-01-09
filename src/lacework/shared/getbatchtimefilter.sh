#!/bin/bash

defaultHrsLoad=$1
prevFilter=$2
if [[ -z "$defaultHrsLoad" ]]; then
    echo "Usage: getbatchtimefilter.sh <default hrs to load, e.g. 24> <previous time filter, if any>"
    exit 1
fi

#echo Previous filter: $prevFilter
prevEndTime=$(echo $prevFilter | jq -r '.endTime')
#echo Previous end time: $prevEndTime
newEndTime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
#echo New end time: $newEndTime

result="{}"

if [ -n "$prevEndTime" ]; then
    result=$(echo $result | jq --arg prevEndTime "$prevEndTime" '.startTime=$prevEndTime')
else
    #Generate start time - different date implementation for mac vs linux vs busybox.
    if [ "$(uname)" == "Darwin" ]; then
        newStartTime=$(date -u -v -${defaultHrsLoad}H +"%Y-%m-%dT%H:%M:%SZ")
    else
        #Assume linux with different date utility
        defaultSecondsLoad=$(( defaultHrsLoad * 60 * 60 ))
        current_epoch=$(date +%s)
        adjusted_epoch=$((current_epoch - defaultSecondsLoad))
        newStartTime=$(date -u -d "@$adjusted_epoch" +"%Y-%m-%dT%H:%M:%SZ")
    fi
    #echo New start time: $newStartTime
    result=$(echo $result | jq --arg newStartTime "$newStartTime" '.startTime=$newStartTime')
fi

result=$(echo $result | jq -c --arg newEndTime "$newEndTime" '.endTime=$newEndTime')
echo $result
