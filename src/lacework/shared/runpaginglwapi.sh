#!/bin/bash
operation=$1
api=$2
payload=$3
destination=$4
echo Operation: $operation
echo API: $api
echo Payload: $payload
echo Destination: $destination

tmpfile="${lwTmpWorkDirectory}/lwapitmp.json"

curl -s -X $operation https://$lwAccount$api --header 'Content-Type: application/json' --header 'Authorization: Bearer '$lwBearerToken'' --data $payload > $tmpfile

cat $tmpfile | jq '.data | .[]' > $destination

nextPage=`cat $tmpfile | jq -r '.paging.urls.nextPage'`
rowsLoaded=`cat $tmpfile | jq -r '.paging.rows'`
totalRows=`cat $tmpfile | jq -r '.paging.totalRows'`
echo Total number of rows: ${totalRows}
echo Loaded ${rowsLoaded} rows

while [[ $nextPage != "null" && -n "$nextPage" ]]
do
    echo Load next page
    curl -s $nextPage --header 'Authorization: Bearer '$lwBearerToken'' > $tmpfile

    cat $tmpfile | jq '.data | .[]' >> $destination

    rows=`cat ${tmpfile} | jq -r '.paging.rows'`
    rowsLoaded=$(($rowsLoaded + $rows))
    echo Loaded ${rowsLoaded} rows
    nextPage=`cat $tmpfile | jq -r '.paging.urls.nextPage'`
done
echo Done loading