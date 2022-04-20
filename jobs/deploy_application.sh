#!/usr/bin/env bash
# Example APPLICATION=crd deploy_application_job.sh
set -e # Exit if error is detected during pipeline execution
#Expects: APPLICATION, KUBE_NAMESPACE, IMAGE ...

# ARGPARSE
while getopts a: flag
do
    case "${flag}" in
        a) APPLICATION=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

echo "======= Running deploy step $(basename "$0") APPLICATION=$APPLICATION, KUBE_NAMESPACE=$KUBE_NAMESPACE ======="
JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${JOBS_DIR}/../shared/vars"

if [ -n "$APPLICATION" ]; then
  ROLLOUT_SCRIPT="${JOBS_DIR}"/../applications/"${APPLICATION}"/gcp/rollout.sh
  if [ -z "$IMAGE" ]; then
      IMAGE="${CI_REGISTRY}/${APPLICATION_NAMESPACE}/${APPLICATION}/${REPO_SUB}${IMAGE_TYPE}"
  fi
  echo "IMAGE=$IMAGE"
  if [ -f "${ROLLOUT_SCRIPT}" ] ; then
    IMAGE=$IMAGE bash "$ROLLOUT_SCRIPT"
  else
    echo  "Error: Invalid path to rollout deployment $ROLLOUT_SCRIPT"
  fi
else
  echo "Error, APPLICATION is not set"
fi


