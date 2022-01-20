#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/../bin/SET
VERSION="latest"

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying Deployment to Cluster $CLUSTER *****"
cd "$GCP"/../k8s/

sed 's|__FHIR_SERVER__|'"$FHIR_SERVER"'|g;
    s|__AUTH__|'"$AUTH"'|g;
    s|__PUBLIC_KEYS__|'"$PUBLIC_KEYS"'|g;
    s|__CDS_SERVICE__|'"$CDS_SERVICE"'|g;' config.sample.yaml > config.yaml
kubectl apply -f config.yaml

sed 's|__IMAGE__|'"$REPO/$APPLICATION"'|g; s|__VERSION__|'"$VERSION"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml


cd "$PWD" || exit

echo "***** DEPLOYED! *****"


