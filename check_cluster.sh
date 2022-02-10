#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR"/shared
print="$UTILS/print"
ZIP="$DIR/CDS-Library.zip"

source "$DIR"/crd/bin/SET #CRD has BUCKET defined since it uses for Cloud Storage Access

enable_project_apis() {
  APIS="compute.googleapis.com \
    storage.googleapis.com \
    container.googleapis.com"

  $print "Enabling APIs on the project..."
  gcloud services enable $APIS
}

configure_container_registry_access(){
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
      --member="serviceAccount:$(gcloud projects describe "$PROJECT_ID" --format='get(projectNumber)')-compute@developer.gserviceaccount.com" \
      --role="roles/storage.admin"

#  CONTAINER_BT=gs://artifacts.${PROJECT_ID}.appspot.com/
#  gsutil iam set gs://"${CONTAINER_BT}" serviceAccount:"${PROJECT_NUMBER}"-compute@developer.gserviceaccount.com:roles/storage.objectViewer
}


create_CDS_Library_zip(){
  $print "Creating new CDS-Library Archive ... "
  PWD=$(pwd)

  cd "$DIR"/..
  zip --exclude '*.git*' -r -q "$ZIP" CDS-Library
  cd "$PWD" || exit
}


create_kservice_account(){
  $print "Preparing KSA service account [$KSA_NAME] in [$KUBE_NAMESPACE] namespace ..."
  if kubectl get namespaces | grep "$KUBE_NAMESPACE"; then
    $print "[$KUBE_NAMESPACE] namespace already exists" INFO
  else
    $print "Creating [$KUBE_NAMESPACE] namespace" INFO
    kubectl create namespace "$KUBE_NAMESPACE"
  fi

  if kubectl get serviceaccounts --namespace "$KUBE_NAMESPACE" | grep -q "$KSA_NAME"; then
    $print "Kubernetes Service account [$KSA_NAME] has been found." INFO
  else
    $print "Creating kubernetes service account [$KSA_NAME]..." INFO
    kubectl create serviceaccount "$KSA_NAME" \
        --namespace "$KUBE_NAMESPACE"
  fi
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

create_gservice_account() {
  $print "Preparing GSA service account [$GSA_NAME] ..."

  # shellcheck disable=SC2153
  if gcloud iam service-accounts list --project "$PROJECT_ID" | grep -q "$GSA_NAME"; then
    $print "Service account [$GSA_NAME] has been found." INFO
  else
    $print "Creating service account [$GSA_NAME] ..." INFO
    gcloud iam service-accounts create "$GSA_NAME" \
        --description="Runs $APPLICATION jobs" \
        --display-name="$APPLICATION-service-account"
  fi

  gsutil iam ch  "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com":objectViewer "${BUCKET}"

  gcloud iam service-accounts get-iam-policy \
      $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

}

configure_kservice_account(){
  $print 'Configuring KSA...'
  gcloud iam service-accounts add-iam-policy-binding $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:$PROJECT_ID.svc.id.goog[$KUBE_NAMESPACE/$KSA_NAME]"

  annotation=$(kubectl get serviceaccount $KSA_NAME -o jsonpath='{.metadata.annotations.iam\.gke\.io\/gcp-service-account}')
  if [ -z "$annotation" ]; then
    kubectl annotate serviceaccount $KSA_NAME \
        --namespace $KUBE_NAMESPACE \
        iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com
  else
    $print "Annotation already exists - $annotation" INFO
  fi
  kubectl describe serviceaccount $KSA_NAME
}

# TODO to be provisioned by DTP
enable_project_apis

#Assign Workload Identity https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubectl

create_CDS_Library_zip

create_bucket

create_gservice_account

create_kservice_account

configure_kservice_account

configure_container_registry_access



