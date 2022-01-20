#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
print=$DIR/shared/print

source "$DIR"/.env
$print 'You are all Done! Use following External IPs to access deployed services'
cat "$DIR"/.env

echo ### Register the test-ehr ###
echo "Go to $DTR:3005/register"
echo "    - Client Id        : app-login"
echo "    - Fhir Server (iss): $TEST_EHR:8080/test-ehr/r4"
echo
echo ### Run the DRLS Flow ###
echo "Go to $CRD_REQUEST_GENERATOR_HOST:3000/ehr-server/reqgen"




