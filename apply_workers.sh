#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function apply_worker(){
  "$DIR/$1/gcp/apply.sh"
}

apply_worker auth
apply_worker crd
apply_worker dtr
apply_worker test-ehr
apply_worker crd-request-generator




