#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function delete(){
  "$DIR/$1/gcp/delete.sh"
}

delete auth
delete crd
delete dtr
delete test-ehr
delete crd-request-generator

source "$DIR"/crd/bin/SET #CRD has BUCKET defined since it uses for Cloud Storage Access
echo "Removing CDS-Library from cloud storage ..."
gcloud alpha storage rm "$BUCKET"/"$DB"


