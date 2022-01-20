#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/../bin/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying Deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/

sed 's|__AUTH__|'"$AUTH"'|g; s|__TEST_EHR__|'"$TEST_EHR"'|g; ' config.sample.yaml > config.yaml
kubectl apply -f config.yaml

sed 's|__IMAGE__|'"$IMAGE"'|g; s|__VERSION__|'"$VERSION"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

cd "$PWD" || exit

echo "***** DEPLOYED! *****"

