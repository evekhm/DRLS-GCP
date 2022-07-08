#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
#UTILS="$GCP"/../../../shared
PWD=$(pwd)
source "$BIN"/SET

echo "$(basename "$0") APPLICATION=$APPLICATION, IMAGE=$IMAGE KUBE_NAMESPACE=$KUBE_NAMESPACE"

cd "$GCP"/../k8s/ || exit

sed 's|__IMAGE__|'"$IMAGE"'|g;'  deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"
kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"

cd "$PWD" || exit



