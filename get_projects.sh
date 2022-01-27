#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
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
  cd "$OUT" || exit
  URL="${GIT_BASE}/$1.git"
  DIR=$1
  BRANCH=$2
  if [ -d "$DIR" ]; then
    # rm -rf "$OUT"
    $print "$OUT/$DIR already exists, skipping ..." WARNING
  else
    $print "Checking out $URL $BRANCH ..."
    git clone "$URL"
    cd "$DIR" || exit
    git checkout "$BRANCH"
  fi

}

checkout CRD gcpDev
checkout dtr gcpDev
checkout crd-request-generator gcpDev
checkout CDS-Library master
checkout test-ehr gcpDev
checkout prior-auth gcpDev

#dtr
#crd-request-generator

$print "Done! $OUT" INFO
ls "$OUT"
cd "$PWD"