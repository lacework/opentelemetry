#!/bin/bash
echo Running hello world!
echo lwBearerToken: $lwBearerToken
echo lwDataDirectory: $lwDataDirectory
echo lwMetricsEndpoint: $lwMetricsEndpoint

testFile=$lwDataDirectory/test.txt
echo $testFile

echo `date` >> $testFile
cat $testFile

echo Do a cool test!
echo $PATH
echo.sh "It is working"
echo Do pause for $lwSecondsPauseAferRun seconds
sleep $lwSecondsPauseAferRun
echo End pause