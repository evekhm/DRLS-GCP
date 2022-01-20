#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function build_image(){
  "$DIR/$1/bin/docker_build"
}

build_image auth
build_image crd
build_image dtr
build_image test-ehr
build_image crd-request-generator



