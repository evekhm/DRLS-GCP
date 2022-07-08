#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function delete(){
  "$DIR/applications/$1/gcp/delete.sh"
}

delete auth
delete crd
delete dtr
delete test-ehr
delete prior-auth
delete crd-request-generator

source "$DIR"/crd/bin/SET #CRD has BUCKET defined since it uses for Cloud Storage Access
echo "Removing CDS-Library from cloud storage ..."
gcloud alpha storage rm "$BUCKET"/"$DB"

if [ -n "$SECRET" ]; then
  if kubectl get secrets --namespace=$KUBE_NAMESPACE | grep $SECRET; then
    kubectl delete secret $SECRET --namespace=$KUBE_NAMESPACE
  fi
fi


