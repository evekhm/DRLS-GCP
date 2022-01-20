#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR"/get_projects.sh
"$DIR"/setup_cluster.sh
"$DIR"/deploy_services.sh
"$DIR"/build_keycloak.sh
"$DIR"/apply_workers.sh

source "$DIR"/.env
echo 'You are all Done! Use following External ips to access deployed services'
cat "$DIR"/.env

echo ### Register the test-ehr ###
echo "Go to http://$DTR:3005/register"
echo "    - Client Id        : app-login"
echo "    - Fhir Server (iss): http://$TEST_EHR:8080/test-ehr/r4"
echo
echo ### Run the DRLS Flow ###
echo "Go to http://$CRD_REQUEST_GENERATOR_HOST:3000/ehr-server/reqgen"
