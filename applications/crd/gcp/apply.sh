#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution


GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

echo "$(basename "$0") APPLICATION=$APPLICATION, IMAGE=$IMAGE BUCKET=$BUCKET KUBE_NAMESPACE=$KUBE_NAMESPACE"

cd "$GCP"/../k8s/
sed 's|__PROJECT_ID__|'"$PROJECT_ID"'|g;
      s|__BUCKET__|'"$BUCKET_NAME"'|g;
      s|__DB__|'"$DB_NAME"'|g;
      s|__VSAC_API_KEY__|'"$VSAC_API_KEY"'|g;
      s|__DTR__|'"$DTR"'|g;
      s|__AUTH__|'"$AUTH"'|g;
      s|__CRD_REQUEST_GENERATOR__|'"$CRD_REQUEST_GENERATOR"'|g;
      s|__TEST_EHR__|'"$TEST_EHR"'|g; ' config.sample.yaml > config.yaml

kubectl apply -f config.yaml --namespace="$KUBE_NAMESPACE"

kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__KSA_NAME__|'"$KSA_NAME"'|g; ' serviceaccount.sample.yaml > serviceaccount.yaml
kubectl apply -f serviceaccount.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__IMAGE__|'"$IMAGE"'|g;
 s|__KSA_NAME__|'"$KSA_NAME"'|g; '  deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

cd "$PWD" || exit


