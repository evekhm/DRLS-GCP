#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -n "$APPLICATION" ]; then
  "$DIR/$APPLICATION/gcp/apply.sh"
fi




