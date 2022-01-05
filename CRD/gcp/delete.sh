#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
source "$DIR"/../bin/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Deleting Deployment from Cluster $CLUSTER *****"
kubectl delete -f config.yaml
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f serviceaccount.yaml

cd "$PWD" || exit

echo "***** Delete Deployment! *****"


