#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR"/get_projects.sh
"$DIR"/setup_cluster.sh
"$DIR"/deploy_services.sh
  "$DIR"/build_keycloak.sh
"$DIR"/apply_workers.sh

"$DIR"/print_steps.sh
