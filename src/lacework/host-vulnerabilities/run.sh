#!/bin/bash
echo Start loading host vulnerabilities

#Load previous filter, if it exists
prevFilterFile=$lwDataDirectory/hostvulnprevfilter.json
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

runpaginglwapi.sh "POST" "/api/v2/Vulnerabilities/Hosts/search" "$completeFilter" "vuln-data.json"

if [ -z "$(head -1 "vuln-data.json")" ]; then
    echo No data, exiting
    exit
fi

currseondstime=$(date +%s)
currnanotime=$((currseondstime * 1000000000))
echo Current time in nanonseconds: $currnanotime
lwUrl="https://$lwAccount/ui/investigation/host/HostVulnerabilityDashboard"

jq --arg currnanotime "$currnanotime" '{
    hostName: .evalCtx.hostname,
    lwMachineid: .mid,
    startTime: $currnanotime,
    riskScore: .hostRiskScore,
    cveCritical: .hostRiskInfo.host_risk_factors_breakdown.cve_counts_by_package_status.Overall.Critical,
    cveHigh: .hostRiskInfo.host_risk_factors_breakdown.cve_counts_by_package_status.Overall.High,
    cveMedium: .hostRiskInfo.host_risk_factors_breakdown.cve_counts_by_package_status.Overall.Medium,
    cveLow: .hostRiskInfo.host_risk_factors_breakdown.cve_counts_by_package_status.Overall.Low,
    cveInfo: .hostRiskInfo.host_risk_factors_breakdown.cve_counts_by_package_status.Overall.Info,
    attributes: .machineTags
}' vuln-data.json | jq -c | sort | uniq | jq '(.attributes | to_entries) as $entries | 
                                  .attributes = $entries | 
                                  .attributes |= map({key: .key, value: {stringValue: .value|tostring}})' |
      jq  --arg lwUrl "$lwUrl" \
          '.attributes += [{
                              "key": "hostName",
                              "value": {stringValue: .hostName}
                          }] | del(.hostName) |
          .attributes += [{
                              "key": "lwMachineid",
                              "value": {intValue: .lwMachineid}
                          }] | del(.lwMachineid) |
          .attributes += [{
                              "key": "lwUrl",
                              "value": {stringValue: $lwUrl}
                          }]' |
      jq '.attributes |= map(select(.value.stringValue != "NOT_AVAILABLE"))' > tmp-condenced-vulnerability-information.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveCritical,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.critical",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of critical CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-critical.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveHigh,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }'| jq 'select(.asDouble != null)'  | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.high",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of high CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-high.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveMedium,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.medium",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of medium CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-medium.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveLow,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.low",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of low CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-low.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .cveInfo,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.cve.info",
                                                                                    unit: "CVEs",
                                                                                    description: "Number of info CVEs",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-info.json

cat tmp-condenced-vulnerability-information.json | jq '{
                                                        asDouble: .riskScore,
                                                        start_time_unix_nano: .startTime,
                                                        time_unix_nano: .startTime,
                                                        attributes: .attributes
                                                        }' | jq 'select(.asDouble != null)' | jq --slurp '.' | jq '{
                                                                                    name: "host.riskscore",
                                                                                    unit: "Risk Score",
                                                                                    description: "Host Risk Score",
                                                                                    gauge: {dataPoints: .}
                                                                                }' > tmp-riskscore.json

ALL_VULNS=`cat tmp-critical.json tmp-high.json tmp-medium.json tmp-low.json tmp-info.json tmp-riskscore.json | jq --slurp '.'`

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
  echo Clean up logs - only keep last $lwStoreExecutionLogsDays executions
  lwStoreExecutionLogsDays=$(($lwStoreExecutionLogsDays + 1))
  ls -t "$lwDataDirectory/logs"* | tail -n +$lwStoreExecutionLogsDays | xargs rm
fi

echo Got `cat final-payload.json | wc -l` lines of json data
echo Sending to opentelmetry
curl -S -X POST -H "Content-Type: application/json" -d @final-payload.json -i ${lwMetricsEndpoint}/v1/metrics

echo ""
echo Updating last filter used
echo $newFilter > $lwDataDirectory/hostvulnprevfilter.json
