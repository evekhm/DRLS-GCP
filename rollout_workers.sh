#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function rollout_worker(){
  "$DIR/$1/gcp/rollout.sh"
}

rollout_worker auth
rollout_worker crd
rollout_worker dtr
rollout_worker test-ehr
rollout_worker prior-auth
rollout_worker crd-request-generator




