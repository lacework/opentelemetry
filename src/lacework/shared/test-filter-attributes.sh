#!/bin/bash

(
biginput='{
  "resourceMetrics": [
    {
      "resource": {
        "attributes": [
          {
            "key": "source",
            "value": {
              "stringValue": "abc.lacework.net"
            }
          }
        ]
      },
      "scopeMetrics": [
        {
          "metrics": [
            {
              "name": "host.cve.critical",
              "unit": "CVEs",
              "description": "Number of critical CVEs",
              "gauge": {
                "dataPoints": [
                  {
                    "asDouble": 0,
                    "start_time_unix_nano": "1705464831000000000",
                    "time_unix_nano": "1705464831000000000",
                    "attributes": [
                      {
                        "key": "Hostname",
                        "value": {
                          "stringValue": "aaa"
                        }
                      },
                      {
                        "key": "InstanceId",
                        "value": {
                          "stringValue": "123"
                        }
                      },
                      {
                        "key": "VmProvider",
                        "value": {
                          "stringValue": "HV"
                        }
                      },
                      {
                        "key": "arch",
                        "value": {
                          "stringValue": "amd64"
                        }
                      },
                      {
                        "key": "lw_InternetExposure",
                        "value": {
                          "stringValue": "Unknown"
                        }
                      },
                      {
                        "key": "os",
                        "value": {
                          "stringValue": "linux"
                        }
                      },
                      {
                        "key": "hostName",
                        "value": {
                          "stringValue": "aaa"
                        }
                      },
                      {
                        "key": "lwMachineid",
                        "value": {
                          "intValue": 1234
                        }
                      },
                      {
                        "key": "riskScore",
                        "value": {
                          "doubleValue": 0.45
                        }
                      }
                    ]
                  },
                  {
                    "asDouble": 0,
                    "start_time_unix_nano": "1705464831000000000",
                    "time_unix_nano": "1705464831000000000",
                    "attributes": [
                      {
                        "key": "Hostname",
                        "value": {
                          "stringValue": "bbb"
                        }
                      },
                      {
                        "key": "InstanceId",
                        "value": {
                          "stringValue": "132132"
                        }
                      },
                      {
                        "key": "arch",
                        "value": {
                          "stringValue": "amd64"
                        }
                      },
                      {
                        "key": "lw_InternetExposure",
                        "value": {
                          "stringValue": "Unknown"
                        }
                      },
                      {
                        "key": "os",
                        "value": {
                          "stringValue": "linux"
                        }
                      },
                      {
                        "key": "hostName",
                        "value": {
                          "stringValue": "bbb"
                        }
                      },
                      {
                        "key": "lwMachineid",
                        "value": {
                          "intValue": 1321312
                        }
                      },
                      {
                        "key": "riskScore",
                        "value": {
                          "doubleValue": 0.08
                        }
                      }
                    ]
                  }
                ]
              }
            },
            {
              "name": "host.cve.medium",
              "unit": "CVEs",
              "description": "Number of medium CVEs",
              "gauge": {
                "dataPoints": [
                  {
                    "asDouble": 62,
                    "start_time_unix_nano": "1705464831000000000",
                    "time_unix_nano": "1705464831000000000",
                    "attributes": [
                      {
                        "key": "Hostname",
                        "value": {
                          "stringValue": "aaa"
                        }
                      },
                      {
                        "key": "InstanceId",
                        "value": {
                          "stringValue": "1234"
                        }
                      },
                      {
                        "key": "arch",
                        "value": {
                          "stringValue": "amd64"
                        }
                      },
                      {
                        "key": "lw_InternetExposure",
                        "value": {
                          "stringValue": "Unknown"
                        }
                      },
                      {
                        "key": "os",
                        "value": {
                          "stringValue": "linux"
                        }
                      },
                      {
                        "key": "hostName",
                        "value": {
                          "stringValue": "aaa"
                        }
                      },
                      {
                        "key": "lwMachineid",
                        "value": {
                          "intValue": 9205767059911918444
                        }
                      },
                      {
                        "key": "riskScore",
                        "value": {
                          "doubleValue": 0.45
                        }
                      }
                    ]
                  },
                  {
                    "asDouble": 31,
                    "start_time_unix_nano": "1705464831000000000",
                    "time_unix_nano": "1705464831000000000",
                    "attributes": [
                      {
                        "key": "Hostname",
                        "value": {
                          "stringValue": "bbb"
                        }
                      },
                      {
                        "key": "arch",
                        "value": {
                          "stringValue": "amd64"
                        }
                      },
                      {
                        "key": "lw_InternetExposure",
                        "value": {
                          "stringValue": "Unknown"
                        }
                      },
                      {
                        "key": "os",
                        "value": {
                          "stringValue": "linux"
                        }
                      },
                      {
                        "key": "hostName",
                        "value": {
                          "stringValue": "bbb"
                        }
                      },
                      {
                        "key": "lwMachineid",
                        "value": {
                          "intValue": 3323409363183319898
                        }
                      },
                      {
                        "key": "riskScore",
                        "value": {
                          "doubleValue": 0.08
                        }
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}'

inputfile='/tmp/test-filter-input.json'
outputfile='/tmp/test-filter-output.json'

echo "$biginput" > $inputfile

result=`./filter-attributes.sh "$inputfile" "$outputfile" "Hostname,InstanceId,lw_InternetExposure,riskScore"`
echo Result:
cat $outputfile

echo No filter test
result=`./filter-attributes.sh "$inputfile" "$outputfile" ""`
echo Result:
cat $outputfile

#echo Empty input
#echo '{}' > $inputfile
#result=`./filter-attributes.sh "$inputfile" "$outputfile" "Hostname,InstanceId,lw_InternetExposure,riskScore"`
#echo Result:
#cat $outputfile

)