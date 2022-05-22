#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
OUT="$DIR"/../
GIT_BASE="https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl"
UTILS="$DIR"/shared
print="$UTILS/print"

if [ ! -d "$OUT" ]; then
  # rm -rf "$OUT"
  mkdir -p "$OUT"
fi

function checkout(){
  URL="${GIT_BASE}/$1.git"
  DIR=$1
  BRANCH=$2
  echo "git clone --branch $BRANCH $URL" >> out
  if [ -d "$DIR" ]; then
    # rm -rf "$OUT"
    echo "$OUT/$DIR already exists, skipping ..."
  else
    echo "Checking out $URL $BRANCH ..."
    git clone --branch "$BRANCH" "$URL"
  fi

}

checkout CRD gcpDev
checkout dtr gcpDev
checkout crd-request-generator gcpDev
checkout CDS-Library master
checkout test-ehr gcpDev
checkout prior-auth gcpDev
checkout gke-deploy-env main
# checkout DRLS-GCP main


$print "Done! $OUT" INFO
ls "$OUT"
cd "$PWD"
