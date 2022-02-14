#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR"/shared
print="$UTILS/print"
ZIP="$DIR/CDS-Library.zip"
BUCKET="gs://${PROJECT_ID}-${APPLICATION}"
#source "$DIR"/crd/bin/SET #CRD has BUCKET defined since it uses for Cloud Storage Access

create_CDS_Library_zip(){
  echo "Creating new CDS-Library Archive ... "
  PWD=$(pwd)

  cd "$DIR"/..
  zip --exclude '*.git*' -r -q "$ZIP" CDS-Library
  cd "$PWD" || exit
}

create_bucket(){
  $print "Preparing Cloud Storage [${BUCKET}] bucket..."
  if gsutil ls | grep "${BUCKET}"; then
      $print "Bucket [$BUCKET] already exists - skipping step" INFO
  else
      $print "Creating GCS bucket for pipeline: [$BUCKET]..." INFO
      gsutil mb -p "$PROJECT_ID" "${BUCKET}"/
  fi
  gsutil cp "${ZIP}" "$BUCKET"/"$DB"

#  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
#    --member="serviceAccount:$SA_DATAFLOW" \
#    --role="roles/storage.admin"
}

create_CDS_Library_zip

create_bucket




