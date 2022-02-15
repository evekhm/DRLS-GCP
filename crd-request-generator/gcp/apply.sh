#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/../bin/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying  $APPLICATION deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/

sed 's|__FHIR_SERVER__|'"$FHIR_SERVER"'|g;
    s|__AUTH__|'"$AUTH"'|g;
    s|__PUBLIC_KEYS__|'"$PUBLIC_KEYS"'|g;
    s|__CDS_SERVICE__|'"$CDS_SERVICE"'|g;' config.sample.yaml > config.yaml
kubectl apply -f config.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__IMAGE_TAG__|'"$IMAGE_TAG"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"


cd "$PWD" || exit

echo "***** DEPLOYED! *****"


