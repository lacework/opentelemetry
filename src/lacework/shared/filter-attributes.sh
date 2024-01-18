#!/bin/bash
inputFile=$1
outputFile=$2
filterAttributes=$3
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: filter-attributes.sh <inputfile> <outputfile> <attributes-to-filter>"
    exit 1
fi

if [[ -z "$3" ]]; then
    echo "No filter set"
    cp $inputFile $outputFile
    exit
fi

# Convert the comma-separated list into an array
IFS=',' read -ra filterArray <<< "$filterAttributes"

# Initialize the condition string
CONDITION=""

# Loop through the array and construct the condition
for key in "${filterArray[@]}"; do
  CONDITION+=" or .key == \"$key\""
done

# Remove the leading " or " from the condition
CONDITION=${CONDITION#* or }

JQFILTER=".resourceMetrics[].scopeMetrics[].metrics[].gauge.dataPoints[].attributes |= map(select($CONDITION))"
cat $inputFile | jq "$JQFILTER" > $outputFile