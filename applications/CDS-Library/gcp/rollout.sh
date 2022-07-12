#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$GCP"/../../../..
source "$GCP"/../../../shared/SET

APPLICATION=$(basename "$(dirname "${GCP}")")
PROJECT_PATH="${APPLICATION_NAMESPACE}/${APPLICATION}"
PROJECT_REPO=${CI_SERVER_HOST}/${PROJECT_PATH}.git
ZIP_FILE="$DB_NAME"
ZIP_PATH="$GCP/.."
ZIP="$ZIP_PATH"/"$ZIP_FILE"

# Requires following settings in the Project->Settings->CI/CD
# CI_DEPLOY_USER, CI_DEPLOY_PASSWORD

echo "$(basename "$0") APPLICATION=$APPLICATION, PROJECT_REPO=$PROJECT_REPO BUCKET=$BUCKET PROJECT_ID=$PROJECT_ID KUBE_NAMESPACE=$KUBE_NAMESPACE"
echo ${CI_DEPLOY_USER} ${CI_DEPLOY_PASSWORD}

git_clone(){
  DD="$ROOT/$APPLICATION"
  if [ ! -d "$DD" ]; then
#    if [ -n "$TOKEN" ]; then
#      git clone https://oauth2:"$TOKEN"@"${PROJECT_REPO}" "$DD"
#    else
      git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@"${PROJECT_REPO}" "$DD"
#    fi
  fi
}


create_CDS_Library_zip(){
  echo "Creating new CDS-Library Archive ... "
  PWD=$(pwd)
  cd "$ROOT"
  zip --exclude '*.git*' -r -q "$ZIP" "$APPLICATION"
  cd "$PWD"
}

create_bucket(){
  echo "Preparing Cloud Storage [${BUCKET}] bucket..."
  RESULT="$(gsutil ls "${BUCKET}" || true)"
  if [[ -n "${RESULT}" ]]; then
      echo "Bucket [$BUCKET] already exists - skipping step" INFO
  else
      echo "Creating GCS bucket for pipeline: [$BUCKET]..." INFO
      gsutil mb -p "$PROJECT_ID" "${BUCKET}"/
  fi
  gsutil iam ch  "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com":objectViewer "${BUCKET}"
  gsutil versioning set on "$BUCKET"
  gsutil cp "$ZIP" "$BUCKET"/"$ZIP_FILE"
}


# Deploys CDS-Library, requires CDS_LIBRARY_TOKEN in the Settings
# Get CDS-Library from GitLab repo, zips and uploads into the GCP Cloud Storage Bucket
git_clone

create_CDS_Library_zip

create_bucket





