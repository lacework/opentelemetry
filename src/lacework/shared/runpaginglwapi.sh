#!/bin/bash
export operation=$1
export api=$2
export payload=$3
#echo Operation: $operation
#echo API: $api
#echo Payload: $payload

mkdir -p $lwDataDirectory
curl -s -X $operation https://$lwAccount$api --header 'Content-Type: application/json' --header 'Authorization: Bearer '$lwBearerToken'' --data $payload > $lwDataDirectory/tmp-data.json

cat $lwDataDirectory/tmp-data.json | jq '.data | .[]' > $lwDataDirectory/tmp-result.json

nextPage=`cat $lwDataDirectory/tmp-data.json | jq -r '.paging.urls.nextPage'`
rowsLoaded=`cat $lwDataDirectory/tmp-data.json | jq -r '.paging.rows'`
totalRows=`cat $lwDataDirectory/tmp-data.json | jq -r '.paging.totalRows'`
#echo Total number of rows: ${totalRows}
#echo Loaded ${rowsLoaded} rows

while [[ $nextPage != "null" && -n "$nextPage" ]]
do
    #echo Load next page
    curl -s $nextPage --header 'Authorization: Bearer '$lwBearerToken'' > $lwDataDirectory/tmp-data.json


    cat $lwDataDirectory/tmp-data.json | jq '.data | .[]' >> $lwDataDirectory/tmp-result.json

    rows=`cat $lwDataDirectory/tmp-data.json | jq -r '.paging.rows'`
    rowsLoaded=$(($rowsLoaded + $rows))
    #echo Loaded ${rowsLoaded} rows
    nextPage=`cat $lwDataDirectory/tmp-data.json | jq -r '.paging.urls.nextPage'`
done

rm $lwDataDirectory/tmp-data.json

cat $lwDataDirectory/tmp-result.json | jq
