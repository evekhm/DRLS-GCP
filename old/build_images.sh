#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function build_image(){
  "$DIR/applications/$1/bin/docker_build"
}

build_image auth
build_image crd
build_image dtr
build_image test-ehr
build_image prior-auth
build_image crd-request-generator




