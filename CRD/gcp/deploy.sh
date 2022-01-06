#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
UTILS="$GCP"/../../bin
BIN="$GCP"/../bin

source "$BIN"/SET

echo "**** Deploying $APPLICATION  ****"

"$BIN"/docker_build

docker push "$IMAGE"

"$GCP"/rollout.sh

"$UTILS"/get_service_external_ip "$APPLICATION"-service


cd "$PWD" || exit


