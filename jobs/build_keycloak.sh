#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# File from the previous step with Service IPs
echo "Running $(basename "$0") VARIABLES_FILE=$VARIABLES_FILE ..."
PWD=$(pwd)

#Keycloak needs TEST_EHR embedded in the image
cat "${VARIABLES_FILE}"
source "${VARIABLES_FILE}"

APPLICATION=auth
"$JOBS_DIR"/build_application.sh -a $APPLICATION



