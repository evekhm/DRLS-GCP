#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying  $APPLICATION  Deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/

kubectl apply -f pv.yaml
kubectl apply -f config.yaml

sed 's|__IMAGE_TAG__|'"$IMAGE_TAG"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml


cd "$PWD" || exit

echo "***** DEPLOYED! *****"


