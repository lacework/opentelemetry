#!/bin/bash
(
    export lwDataDirectory="/tmp/lw-test-prevrange"
    export datafile=$lwDataDirectory/prevbatchtimefilter.json
    rm $datafile
    rm -rf lwDataDirectory

    echo Dummy test
    ./getbatchtimefilter.sh

    echo ""
    echo Test with empty range - expect start 24 hrs back, defined endTime
    ./getbatchtimefilter.sh 24 ""

    echo ""
    echo Generating current filter - expect start to equals 2024-01-08T15:49:37Z
    echo '{"endTime":"2024-01-08T15:49:37Z"}'  > $lwDataDirectory/prevbatchtimefilter.json
    ./getbatchtimefilter.sh 24 '{"endTime":"2024-01-08T15:49:37Z"}'

    echo ""
    echo Generating fully defined filter - expect start time to equals 2024-01-08T15:52:23Z
    echo '{"startTime":"2024-01-08T15:49:37Z","endTime":"2024-01-08T15:52:23Z"}'  > $lwDataDirectory/prevbatchtimefilter.json
    ./getbatchtimefilter.sh 24 '{"startTime":"2024-01-08T15:49:37Z","endTime":"2024-01-08T15:52:23Z"}'
)
