#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$GCP"/../bin/SET

echo "**** Deploying $APPLICATION to GKE $CLUSTER cluster ****"

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"
kubectl apply -f "$GCP"/../k8s
"$GCP"/../../shared/get_service_external_ip "$APPLICATION"