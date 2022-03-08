#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
source "$GCP"/../bin/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Deleting $APPLICATION deployment at cluster $CLUSTER *****"
cd "$GCP"/../k8s/ || exit

if [ -f deployment.yaml ]; then
  kubectl delete -f deployment.yaml
fi

if [ -f config.yaml ]; then
  kubectl delete -f config.yaml
fi

if [ -f serviceaccount.yaml ]; then
  kubectl delete -f serviceaccount.yaml
fi
kubectl delete -f service.yaml
cd "$PWD" || exit
echo "***** Deleted deployment for $APPLICATION ! *****"


