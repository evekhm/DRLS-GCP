#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
UTILS="$GCP"/../../shared
PWD=$(pwd)
source "$BIN"/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying  $APPLICATION deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/ || exit


sed 's|__IMAGE_TAG__|'"$IMAGE_TAG"'|g;'  deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"

IP=$("$UTILS/get_service_external_ip_port" "$APPLICATION"-service)
echo "External IP for $APPLICATION-service " "$IP"

cd "$PWD" || exit



