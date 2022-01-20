#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
UTILS="$GCP"/../../shared
PWD=$(pwd)
source "$BIN"/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying Deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/ || exit


sed 's|__IMAGE__|'"$IMAGE"'|g;
 s|__VERSION__|'"$VERSION"'|g;'  deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

IP=$("$UTILS/get_service_external_ip_port" "$APPLICATION"-service)
echo "External IP for $APPLICATION-service " "$IP"

cd "$PWD" || exit



