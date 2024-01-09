#!/bin/bash
echo Start loading container vulnerabilities

#Load previous filter, if it exists
prevFilterFile=$lwDataDirectory/hostvulnprevfilter.json
mkdir -p $lwDataDirectory
touch $prevFilterFile
prevFilter=$(cat $prevFilterFile)
echo Previous filter: $prevFilter
newFilter=$(getbatchtimefilter.sh 24 $prevFilter)

completeFilter="{\"timeFilter\":$newFilter}"
echo New filter: $newFilter
echo Complete filter: $completeFilter

runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Hosts/search" "$completeFilter" > $lwDataDirectory/vuln-data.json

if [ -z "$(cat "$lwDataDirectory/vuln-data.json")" ]; then
    echo No data, exiting
    exit
fi

currseondstime=$(date +%s)
currnanotime=$((currseondstime * 1000000000))
echo Currnent time in nanonseconds: $currnanotime


cat $lwDataDirectory/vuln-data.json | jq --arg currnanotime "$currnanotime" '{
    hostName: .evalCtx.hostname,
    lwMachineid: .mid,
    startTime: $currnanotime,
    riskScore: .riskScore,
    cveCritical: .riskInfo.factors_breakdown.cve_counts_by_package_status.Overall.Critical,
    cveHigh: .riskInfo.factors_breakdown.cve_counts_by_package_status.Overall.High,
    cveMedium: .riskInfo.factors_breakdown.cve_counts_by_package_status.Overall.Medium,
    cveLow: .riskInfo.factors_breakdown.cve_counts_by_package_status.Overall.Low,
    cveInfo: .riskInfo.factors_breakdown.cve_counts_by_package_status.Overall.Info,
    attributes: .machineTags
}' | jq -c | sort | uniq | jq '(.attributes | to_entries) as $entries | 
                                  .attributes = $entries | 
                                  .attributes |= map({key: .key, value: {stringValue: .value}})' |
      jq  '.attributes += [{
                              "key": "hostName",
                              "value": {stringValue: .hostName}
                          }] | del(.hostName) |
          .attributes += [{
                              "key": "lwMachineid",
                              "value": {intValue: .lwMachineid}
                          }] | del(.lwMachineid) |
          .attributes += [{
                              "key": "riskScore",
                              "value": {doubleValue: .riskScore}
                          }] | del(.riskScore)' |
      jq '.attributes |= map(select(.value.stringValue != "NOT_AVAILABLE"))' > $lwDataDirectory/tmp-condenced-vulnerability-information.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveCritical,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.critical",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of critical CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-critical.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveHigh,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }'| jq 'select(.asDouble != null)'  | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.high",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of high CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-high.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveMedium,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.medium",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of medium CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > $lwDataDirectory/tmp-medium.json

cat $lwDataDirectory/tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveInfo,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.info",
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
echo $newFilter > $lwDataDirectory/hostvulnprevfilter.json
