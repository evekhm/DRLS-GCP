#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Configuring Cluster $CLUSTER for $APPLICATION application*****"
cd "$GCP"/../k8s/

sed 's|__PROJECT_ID__|'"$PROJECT_ID"'|g;
      s|__BUCKET__|'"$BUCKET_NAME"'|g;
      s|__DB__|'"$DB"'|g;
      s|__VSAC_API_KEY__|'"$VSAC_API_KEY"'|g;
      s|__DTR__|'"$DTR"'|g;
      s|__CRD_REQUEST_GENERATOR__|'"$CRD_REQUEST_GENERATOR"'|g;
      s|__TEST_EHR__|'"$TEST_EHR"'|g; ' config.sample.yaml > config.yaml

kubectl apply -f config.yaml

sed 's|__IMAGE__|'"$IMAGE"'|g; s|__KSA_NAME__|'"$KSA_NAME"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

sed 's|__KSA_NAME__|'"$KSA_NAME"'|g; ' serviceaccount.sample.yaml > serviceaccount.yaml
kubectl apply -f serviceaccount.yaml

cd "$PWD" || exit

echo "***** Configured! *****"


