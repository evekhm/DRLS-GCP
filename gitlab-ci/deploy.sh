#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
#Expects: KUBE_NAMESPACE, KSA_NAME, GSA_NAME, PROJECT_ID
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Running deploy step with following parameters APPLICATON=$APPLICATION,
      KUBE_CONTEXT=$KUBE_CONTEXT, KUBE_NAMESPACE=$KUBE_NAMESPACE IMAGE=$IMAGE"

apt-get update && apt-get install git
apt-get install zip unzip -q

if [ -f "${VARIABLES_FILE}" ]; then
  cat "${VARIABLES_FILE}"
fi
source "${VARIABLES_FILE}"
source "${DIR}/../shared/vars"

#"${DIR}"/../jobs/get_services.sh -o "${DIR}"/.env
#cat "${DIR}"/.env
#source "${DIR}"/.env
#rm -rf "${DIR}"/.env

gcloud auth activate-service-account --key-file "${SERVICE_ACCOUNT_FILE}" --project="$PROJECT_ID"
"${DIR}"/../jobs/deploy_application.sh -a "$APPLICATION"

