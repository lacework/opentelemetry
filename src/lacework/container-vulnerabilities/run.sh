#!/bin/bash
echo Start loading container vulnerabilities

#Load previous filter, if it exists
prevFilterFile=$lwDataDirectory/containervulnprevfilter.json
mkdir -p $lwDataDirectory
touch $prevFilterFile
prevFilter=$(cat $prevFilterFile)
echo Previous filter: $prevFilter
newFilter=$(getbatchtimefilter.sh 24 $prevFilter)

completeFilter="{\"timeFilter\":$newFilter}"
echo New filter: $newFilter
echo Complete filter: $completeFilter

runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Containers/search" "$completeFilter" > $lwDataDirectory/vuln-data.json

if [ -z "$(cat "$lwDataDirectory/vuln-data.json")" ]; then
    echo No data, exiting
    exit
fi

currseondstime=$(date +%s)
currnanotime=$((currseondstime * 1000000000))
echo Currnent time in nanonseconds: $currnanotime

cat $lwDataDirectory/vuln-data.json | jq --arg currnanotime "$currnanotime" '{
    digest: .evalCtx.image_info.digest,
    lwImageId: .evalCtx.image_info.id,
    registry: .evalCtx.image_info.registry,
    repo: .evalCtx.image_info.repo,
    tags: .evalCtx.image_info.tags,
    lwEvalGuid: .evalGuid,
    cveCritical: .riskInfo.factors_breakdown.cve_counts.Critical,
    cveHigh: .riskInfo.factors_breakdown.cve_counts.High,
    cveMedium: .riskInfo.factors_breakdown.cve_counts.Medium,
    cveInfo: .riskInfo.factors_breakdown.cve_counts.Other,
    activeContainers: .riskInfo.factors_breakdown.active_containers,
    scanStartTimeNanos: $currnanotime,
    scanEndTimeNanos: $currnanotime
} | .tags |= join(", ")' | jq -c | sort | uniq | jq '.attributes += [{
                                                                    "key": "digest",
                                                                    "value": {stringValue: .digest}
                                                                }] | del(.digest) |
                                                    .attributes += [{
                                                                    "key": "lwImageId",
                                                                    "value": {stringValue: .lwImageId}
                                                                }] | del(.lwImageId) |
                                                    .attributes += [{
                                                                    "key": "fullImageName",
                                                                    "value": {stringValue: (.registry + "/" + .repo + ":" + .tags)}
                                                                }] |
                                                    .attributes += [{
                                                                    "key": "registry",
                                                                    "value": {stringValue: .registry}
                                                                }] | del(.registry) |
                                                    .attributes += [{
                                                                    "key": "repo",
                                                                    "value": {stringValue: .repo}
                                                                }] | del(.repo) |
                                                    .attributes += [{
                                                                    "key": "tags",
                                                                    "value": {stringValue: .tags}
                                                                }] | del(.tags) |
                                                    .attributes += [{
                                                                    "key": "activeContainers",
                                                                    "value": {intValue: .activeContainers}
                                                                }] | del(.activeContainers) | del(.lwEvalGuid)' > $lwDataDirectory/tmp-condenced-vulnerability-information.json


cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveCritical,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.critical",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of critical CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-critical.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveHigh,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.high",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of high CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-high.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveMedium,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.medium",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of medium CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-medium.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveInfo,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.info",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of info CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-info.json


ALL_VULNS=`cat $lwDataDirectory/tmp-critical.json $lwDataDirectory/tmp-high.json $lwDataDirectory/tmp-medium.json $lwDataDirectory/tmp-info.json | jq --slurp '.'`

echo "{
  \"resourceMetrics\": [
    {
      \"resource\": {
        \"attributes\": [
          {
            \"key\": \"source\",
            \"value\": {
              \"stringValue\": \"$lwAccount\"
            }
          }
        ]
      },
      \"scopeMetrics\": [
        {
          \"metrics\": ${ALL_VULNS}
        }
      ]
    }
  ]
}"  | jq > $lwDataDirectory/tmp-payload.json

echo Got `cat $lwDataDirectory/tmp-payload.json | wc -l` lines of json data
echo Sending to opentelmetry
curl -S -X POST -H "Content-Type: application/json" -d @$lwDataDirectory/tmp-payload.json -i ${lwMetricsEndpoint}/v1/metrics

echo ""
echo Updating last filter used
echo $newFilter > $lwDataDirectory/containervulnprevfilter.json