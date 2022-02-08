#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function push_image(){
  "$DIR/$1/bin/docker_push"
}

push_image crd
push_image dtr
push_image test-ehr
push_image prior-auth
push_image crd-request-generator




