#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET


echo "$(basename "$0") APPLICATION=$APPLICATION, IMAGE=$IMAGE KUBE_NAMESPACE=$KUBE_NAMESPACE"
cd "$GCP"/../k8s/

kubectl apply -f pv.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__PRIOR_AUTH__|'"$PRIOR_AUTH"'|g;
     s|__TEST_EHR__|'"$TEST_EHR"'|g; ' config.sample.yaml > config.yaml
kubectl apply -f config.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__IMAGE__|'"$IMAGE"'|g;' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"

cd "$PWD" || exit


