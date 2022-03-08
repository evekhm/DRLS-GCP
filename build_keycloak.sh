#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$DIR/applications/auth/bin/docker_build"
"$DIR/applications/auth/bin/docker_push"




