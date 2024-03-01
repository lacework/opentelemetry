#!/bin/bash
echo Start loading container vulnerabilities

#Load previous filter, if it exists
prevFilterFile=$lwDataDirectory/containervulnprevfilter.json
mkdir -p $lwDataDirectory
mkdir -p $lwTmpWorkDirectory
cd $lwTmpWorkDirectory
touch $prevFilterFile
prevFilter=$(cat $prevFilterFile)
echo Previous filter: $prevFilter
newFilter=$(getbatchtimefilter.sh 24 $prevFilter)

completeFilter="{\"timeFilter\":$newFilter}"
echo New filter: $newFilter
echo Complete filter: $completeFilter

runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Containers/search" "$completeFilter" "vuln-data.json"

if [ -z "$(head -1 "vuln-data.json")" ]; then
    echo No data, exiting
    exit
fi

currseondstime=$(date +%s)
currnanotime=$((currseondstime * 1000000000))
echo Current time in nanonseconds: $currnanotime
lwUrl="https://$lwAccount/ui/investigation/container/VulnerabilityDashboard"

jq --arg currnanotime "$currnanotime" '{
    digest: .evalCtx.image_info.digest,
    lwImageId: .evalCtx.image_info.id,
    registry: .evalCtx.image_info.registry,
    repo: .evalCtx.image_info.repo,
    tags: .evalCtx.image_info.tags,
    lwEvalGuid: .evalGuid,
    riskScore: (.imageRiskScore // 0),
    cveCritical: (.imageRiskInfo.factors_breakdown.cve_counts.Critical // 0),
    cveHigh: (.imageRiskInfo.factors_breakdown.cve_counts.High // 0),
    cveMedium: (.imageRiskInfo.factors_breakdown.cve_counts.Medium // 0),
    cveInfo: (.imageRiskInfo.factors_breakdown.cve_counts.Other // 0),
    activeContainers: (.imageRiskInfo.factors_breakdown.active_containers // 0),
    scanStartTimeNanos: $currnanotime,
    scanEndTimeNanos: $currnanotime
} | .tags |= join(", ")' vuln-data.json | jq -c | sort | uniq | jq --arg lwUrl "$lwUrl" \
                                                    '.attributes += [{
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
                                                                        "key": "lwUrl",
                                                                        "value": {stringValue: $lwUrl}
                                                                    }] | del(.lwEvalGuid)' > tmp-condenced-vulnerability-information.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveCritical,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.critical",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of critical CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-critical.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveHigh,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.high",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of high CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-high.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveMedium,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.medium",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of medium CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-medium.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveInfo,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.cve.info",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of info CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-info.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .riskScore,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.riskscore",
                                                                                    unit: "Risk Score",
                                                                                    description: "Container Risk Score",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-riskscore.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .activeContainers,
                                                        start_time_unix_nano: .scanStartTimeNanos,
                                                        time_unix_nano: .scanEndTimeNanos,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "container.activecontainers",
                                                                                    unit: "Active Containers",
                                                                                    description: "Number of Active Containers",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-activecontainers.json

ALL_VULNS=`cat tmp-critical.json tmp-high.json tmp-medium.json tmp-info.json tmp-riskscore.json tmp-activecontainers.json | jq --slurp '.'`

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
}"  | jq > tmp-payload.json

filter-attributes.sh "tmp-payload.json" "final-payload.json" "$lwAttributeFilter"

if [ "$lwStoreExecutionLogs" = "true" ]; then
  echo Store logs
  logFileName="$lwDataDirectory/logs-`date`.tar.gz"
  logFileName="${logFileName// /-}"
  tar czf "$logFileName" $lwTmpWorkDirectory/*
  echo Clean up logs - only keep last 5 executions
  ls -t "$lwDataDirectory/logs"* | tail -n +6 | xargs rm
fi

echo Got `cat final-payload.json | wc -l` lines of json data
echo Sending to opentelmetry
curl -S -X POST -H "Content-Type: application/json" -d @final-payload.json -i ${lwMetricsEndpoint}/v1/metrics

echo ""
echo Updating last filter used
echo $newFilter > $lwDataDirectory/containervulnprevfilter.json
