#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR"/get_projects.sh
"$DIR"/setup_cluster.sh
"$DIR"/deploy_services.sh
"$DIR"/build_keycloak.sh
"$DIR"/apply_workers.sh

echo 'You are all Done! Use following External ips to access deployed services'
cat "$DIR"/.env