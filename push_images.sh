#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function push_image(){
  "$DIR/$1/bin/docker_push"
}

push_image crd
push_image dtr
push_image test-ehr
push_image crd-request-generator




