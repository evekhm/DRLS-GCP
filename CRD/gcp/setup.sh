#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$GCP"/../bin/SET

configure_cloud_build(){
  echo 'TODO'
#  gcloud projects add-iam-policy-binding $PROJECT_ID \
#      --member="service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
#      --role="roles/cloudbuild.serviceAgent"
}

create_CDS_Library_zip(){
  echo "Creating new CDS-Library Archive ... "
  PWD=$(pwd)
  cd "$GCP"/../../../CRD
  zip --exclude '*.git*' -r CDS-Library.zip CDS-Library
  mv CDS-Library.zip "$LOCAL_PATH"
  cd "$PWD" || exit
}

create_kservice_account(){
  echo 'Preparing KSA service account...'
  if kubectl get namespaces | grep "$K8S_NAMESPACE"; then
    echo "$K8S_NAMESPACE" 'already exists'
  else
    kubectl create namespace "$K8S_NAMESPACE"
  fi

  if kubectl get serviceaccounts | grep -q "$KSA_NAME"; then
    echo "Kubernetes Service account $KSA_NAME has been found."
  else
    echo "Creating kubernetes service account... $KSA_NAME"
    kubectl create serviceaccount "$KSA_NAME" \
        --namespace "$K8S_NAMESPACE"
  fi
}

create_bucket(){
  echo 'Preparing Cloud Storage...'
  if gsutil ls | grep "${BUCKET}"; then
      echo "Bucket [$BUCKET] already exists - skipping step"
  else
      echo "Creating GCS bucket for pipeline: [$BUCKET]..."
      gsutil mb -p "$PROJECT_ID" "${BUCKET}"/
  fi
  gsutil cp "${LOCAL_PATH}" "$BUCKET"/"$DB"
}

setup_cluster() {
  echo 'Setting up Cluster...'
  if gcloud container clusters list --region=$REGION --format "value(NAME)" | grep "$CLUSTER" > /dev/null;
  then
    echo "Cluster $CLUSTER already running in $REGION"
  else
    echo "Creating  $CLUSTER in $REGION"
    gcloud container clusters create-auto "$CLUSTER" \
        --region "$REGION" \
        --project="$PROJECT_ID"
  fi

  #gcloud container clusters create CLUSTER --workload-pool=PROJECT_ID.svc.id.goog
  gcloud container clusters get-credentials "$CLUSTER" --region="$REGION"
}

create_gservice_account() {
  echo 'Preparing GSA service account...'

  # shellcheck disable=SC2153
  if gcloud iam service-accounts list --project "$PROJECT_ID" | grep -q "$GSA_NAME"; then
    echo "Service account $GSA_NAME has been found."
  else
    echo "Creating service account... $GSA_NAME"
    gcloud iam service-accounts create "$GSA_NAME" \
        --description="Runs $APPLICATION jobs" \
        --display-name="$APPLICATION-service-account"
  fi

  gsutil iam ch  "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com":objectViewer "${BUCKET}"

  gcloud iam service-accounts get-iam-policy \
      $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

}

configure_kservice_account(){
  echo 'Configuring KSA...'
  gcloud iam service-accounts add-iam-policy-binding $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:$PROJECT_ID.svc.id.goog[$K8S_NAMESPACE/$KSA_NAME]"

  annotation=$(kubectl get serviceaccount $KSA_NAME -o jsonpath='{.metadata.annotations.iam\.gke\.io\/gcp-service-account}')
  if [ -z "$annotation" ]; then
    kubectl annotate serviceaccount $KSA_NAME \
        --namespace $K8S_NAMESPACE \
        iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com
  else
    echo "Annotation already exists - $annotation"
  fi
  kubectl describe serviceaccount $KSA_NAME
}

configure_cloud_build

setup_cluster

#Assign Workload Identity https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubectl

create_CDS_Library_zip

create_bucket

create_gservice_account

create_kservice_account

configure_kservice_account



