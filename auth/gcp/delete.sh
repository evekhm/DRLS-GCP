#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Deleting $APPLICATION deployment at cluster $CLUSTER *****"
cd "$GCP"/../k8s/ || exit

if [ -f deployment.yaml ]; then
  kubectl delete -f deployment.yaml
fi
kubectl delete -f service.yaml
echo "***** Deleted deployment for $APPLICATION ! *****"

cd "$PWD" || exit



