#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function deploy_worker(){
  "$DIR/$1/gcp/deploy.sh"
}

deploy_worker auth
deploy_worker crd
deploy_worker dtr
deploy_worker test-ehr
deploy_worker prior-auth
deploy_worker crd-request-generator




