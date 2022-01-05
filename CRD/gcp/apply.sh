#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
source "$DIR"/../bin/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Applying Deployment to Cluster $CLUSTER *****"
cd "$DIR"/../k8s/

sed 's|__PROJECT_ID__|'"$PROJECT_ID"'|g; s|__BUCKET__|'"$BUCKET_NAME"'|g; s|__DB__|'"$DB"'|g;' config.sample.yaml > config.yaml
kubectl apply -f config.yaml

sed 's|__IMAGE__|'"$IMAGE"'|g; s|__KSA_NAME__|'"$KSA_NAME"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

sed 's|__KSA_NAME__|'"$KSA_NAME"'|g; ' serviceaccount.sample.yaml > serviceaccount.yaml
kubectl apply -f serviceaccount.yaml

cd "$PWD" || exit

echo "***** DEPLOYED! *****"


