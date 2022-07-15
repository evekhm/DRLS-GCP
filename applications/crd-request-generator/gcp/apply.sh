#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
PWD=$(pwd)
source "$BIN"/SET

echo "$(basename "$0") APPLICATION=$APPLICATION, IMAGE=$IMAGE KUBE_NAMESPACE=$KUBE_NAMESPACE"

cd "$GCP"/../k8s/
sed 's|__FHIR_SERVER__|'"$FHIR_SERVER"'|g;
    s|__AUTH__|'"$AUTH"'|g; # TODO replace __TOKEN__
    s|__PUBLIC_KEYS__|'"$PUBLIC_KEYS"'|g;
    s|__DTR__|'"$DTR"'|g;
    s|__CRD_REQUEST_GENERATOR_CONFIG__|'"$CRD_REQUEST_GENERATOR_CONFIG"'|g;
    s|__ORDER_SELECT__|'"$ORDER_SELECT"'|g;
    s|__ORDER_SIGN__|'"$ORDER_SIGN"'|g;
    s|__CDS_SERVICE__|'"$CDS_SERVICE"'|g;' config.sample.yaml > config.yaml
kubectl apply -f config.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__IMAGE__|'"$IMAGE"'|g;
    s|__CRD_REQUEST_GENERATOR_DEPLOYMENT__|'"$CRD_REQUEST_GENERATOR_DEPLOYMENT"'|g;
    s|__PA_SECRET__|'"$PA_SECRET"'|g;
    ' deployment.sample.yaml > deployment.yaml
kubectl apply -f deployment.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__CRD_REQUEST_GENERATOR_SERVICE__|'"$CRD_REQUEST_GENERATOR_SERVICE"'|g;' service.sample.yaml > service.yaml
kubectl apply -f service.yaml --namespace="$KUBE_NAMESPACE"

sed 's|__PA_SECRET__|'"$PA_SECRET"'|g;
    s|__FHIR_ACCESS_TOKEN__|'"$FHIR_ACCESS_TOKEN"'|g;
    s|__CDS_ACCESS_TOKEN__|'"$CDS_ACCESS_TOKEN"'|g;
    s|__CDS_SECRET__|'"$CDS_SECRET"'|g;
' secret.sample.yaml > secret.yaml
kubectl apply -f secret.yaml --namespace="$KUBE_NAMESPACE"

cd "$PWD" || exit


