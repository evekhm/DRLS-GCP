#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function deploy_worker(){
  "$DIR/$1/gcp/deploy.sh"
}

deploy_worker auth
deploy_worker crd
deploy_worker dtr
deploy_worker test-ehr
deploy_worker crd-request-generator




