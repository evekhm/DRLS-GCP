#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
#Expects: KUBE_NAMESPACE, KSA_NAME, GSA_NAME, PROJECT_ID
set -x

#Pre-pare steps:
# 1. Each deployment has its own IP assigned to services, following steps are deployment specific:
# Deploy services, because those IP are needed for Deployments
# Build and deploy keycloak, because it has IP address built in the Image of the service

# 2. Project-ID specific steps
# Service Account required for CRD to access Cloud Storage (with CQL rules)

#KUBE_NAMESPACE specific steps
# Create KSA, secret (done part of .deploy template)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/../shared/vars"
gcloud auth activate-service-account --key-file "${SERVICE_ACCOUNT_FILE}" --project="$PROJECT_ID"

"$DIR"/jobs/prepare_job.sh
