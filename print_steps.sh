#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
print=$DIR/shared/print

source "$DIR"/.env
$print 'You are all Done! Use following External IPs to access deployed services'
cat "$DIR"/.env

$print "### Register the test-ehr ###" INFO
echo "Go to $DTR/register"
echo "    - Client Id        : app-login"
echo "    - Fhir Server (iss): $TEST_EHR/test-ehr/r4"
echo
$print "### Run the DRLS Flow ###" INFO
echo "Go to $CRD_REQUEST_GENERATOR_HOST:3000/ehr-server/reqgen"




