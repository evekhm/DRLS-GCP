#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET


echo "$(basename "$0") APPLICATION=$APPLICATION, IMAGE=$IMAGE KUBE_NAMESPACE=$KUBE_NAMESPACE"
cd "$GCP"/../k8s/

sed 's|__PROJECT_ID__|'"$PROJECT_ID"'|g;
      s|__BUCKET__|'"$BUCKET_NAME"'|g;
      s|__PRIOR_AUTH__|'"$PRIOR_AUTH"'|g;
      s|__DB__|'"$DB_NAME"'|g; ' config.sample.yaml > config.yaml
kubectl apply -f config.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__KSA_NAME__|'"$KSA_NAME"'|g; ' serviceaccount.sample.yaml > serviceaccount.yaml
kubectl apply -f serviceaccount.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__IMAGE__|'"$IMAGE"'|g;
 s|__KSA_NAME__|'"$KSA_NAME"'|g; '  deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"

cd "$PWD" || exit


