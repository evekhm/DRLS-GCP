#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

# gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"

echo "***** Configuring cluster $CLUSTER for $APPLICATION application *****"
cd "$GCP"/../k8s/

sed 's|__PROJECT_ID__|'"$PROJECT_ID"'|g;
      s|__BUCKET__|'"$BUCKET_NAME"'|g;
      s|__DB__|'"$DB"'|g;
      s|__VSAC_API_KEY__|'"$VSAC_API_KEY"'|g;
      s|__DTR__|'"$DTR"'|g;
      s|__AUTH__|'"$AUTH"'|g;
      s|__CRD_REQUEST_GENERATOR__|'"$CRD_REQUEST_GENERATOR"'|g;
      s|__TEST_EHR__|'"$TEST_EHR"'|g; ' config.sample.yaml > config.yaml

kubectl apply -f config.yaml

sed 's|__KSA_NAME__|'"$KSA_NAME"'|g; ' serviceaccount.sample.yaml > serviceaccount.yaml
kubectl apply -f serviceaccount.yaml

sed 's|__IMAGE_TAG__|'"$IMAGE_TAG"'|g;
 s|__KSA_NAME__|'"$KSA_NAME"'|g; '  deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

cd "$PWD" || exit

echo "***** Configured! *****"


