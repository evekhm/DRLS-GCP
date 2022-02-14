#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
#Expects: BUCKET, PROJECT_ID, GSA_NAME

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR"/shared
print="$UTILS/print"
DB="CDS-Library.zip"
ZIP="${DIR}/$DB"

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
  gsutil iam ch  "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com":objectViewer "${BUCKET}"
  gsutil cp "${ZIP}" "$BUCKET"/"$DB"
}

create_CDS_Library_zip

create_bucket




