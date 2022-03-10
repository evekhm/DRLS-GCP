#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying  $APPLICATION  Deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/

kubectl apply -f pv.yaml --namespace="$KUBE_NAMESPACE"
kubectl apply -f config.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__IMAGE__|'"$IMAGE"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"


cd "$PWD" || exit

echo "***** DEPLOYED! *****"


