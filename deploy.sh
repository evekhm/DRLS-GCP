#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
#Expects: KUBE_NAMESPACE, KSA_NAME, GSA_NAME, PROJECT_ID
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/vars"

export ENV=${VARIABLES_FILE}
echo "Running deploy step with following parameters KUBE_CONTEXT=$KUBE_CONTEXT, NAMESPACE=$NAMESPACE"
if [ -n "$APPLICATION" ]; then
  APPLY_SCRIPT="${DIR}"/applications/"${APPLICATION}"/gcp/apply.sh
  if [ -f "${APPLY_SCRIPT}" ] ; then
    PROJECT_ID=$PROJECT_ID BUCKET=$BUCKET bash "$APPLY_SCRIPT"
  else
    echo  "Error: Invalid path to apply deployment $APPLY_SCRIPT"
  fi
else
  echo "Error, APPLICATION is not set"
fi

echo "-----  End deploy step... -----"

