#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function apply_worker(){
  "$DIR/applications/$1/gcp/apply.sh"
}

apply_worker auth
apply_worker crd
apply_worker dtr
apply_worker test-ehr
apply_worker crd-request-generator
apply_worker prior-auth

"$DIR"/print_steps.sh



