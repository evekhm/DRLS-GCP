#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR"/shared
print="$UTILS/print"
ZIP="$DIR/CDS-Library.zip"

source "$DIR"/CRD/bin/SET #CRD has BUCKET defined since it uses for Cloud Storage Access

enable_project_apis() {
  APIS="compute.googleapis.com \
    storage.googleapis.com \
    container.googleapis.com"

  $print "Enabling APIs on the project..."
  gcloud services enable $APIS
}

configure_cloud_build(){
  $print 'TODO enable CLoud Build'
#  gcloud projects add-iam-policy-binding $PROJECT_ID \
#      --member="service-$PROJECT_NUMBER@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
#      --role="roles/cloudbuild.serviceAgent"
}

create_CDS_Library_zip(){
  $print "Creating new CDS-Library Archive ... "
  PWD=$(pwd)

  cd "$DIR"/..
  zip --exclude '*.git*' -r -q "$ZIP" CDS-Library
  cd "$PWD" || exit
}

setup_network(){
  network=$(gcloud compute networks list --filter="name=( $NETWORK )" --format='get(NAME)' 2>/dev/null)
  if [ -z "$network" ]; then
      $print "Setting up [$NETWORK] network... "
      gcloud compute networks create "$NETWORK" --project="$PROJECT_ID" \
      --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional
      gcloud compute firewall-rules create default-allow-internal-"$NETWORK" --project="$PROJECT_ID" \
            --network=projects/"$PROJECT_ID"/global/networks/"$NETWORK" \
            --description=Allows\ connections\ from\ any\ source\ in\ the\ network\ IP\ range\ to\ any\ instance\ on\ the\ network\ using\ all\ protocols. \
            --direction=INGRESS --priority=65534 --source-ranges=10.128.0.0/9 --action=ALLOW --rules=all
  fi
}

create_kservice_account(){
  $print "Preparing KSA service account [$KSA_NAME] in [$K8S_NAMESPACE] namespace ..."
  if kubectl get namespaces | grep "$K8S_NAMESPACE"; then
    $print "[$K8S_NAMESPACE] namespace already exists" INFO
  else
    $print "Creating [$K8S_NAMESPACE] namespace" INFO
    kubectl create namespace "$K8S_NAMESPACE"
  fi

  if kubectl get serviceaccounts | grep -q "$KSA_NAME"; then
    $print "Kubernetes Service account [$KSA_NAME] has been found." INFO
  else
    $print "Creating kubernetes service account [$KSA_NAME]..." INFO
    kubectl create serviceaccount "$KSA_NAME" \
        --namespace "$K8S_NAMESPACE"
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

setup_cluster() {
  $print "Setting up [$CLUSTER] cluster..."
  if gcloud container clusters list --region="$REGION" --format "value(NAME)" | grep "$CLUSTER" > /dev/null;
  then
    $print "Cluster [$CLUSTER] already up and running in [$REGION]" INFO
  else
    $print "Creating  [$CLUSTER] cluster in [$REGION] region..." INFO
    gcloud container clusters create-auto "$CLUSTER" \
        --region "$REGION" \
        --network "$NETWORK" \
        --project="$PROJECT_ID"
  fi

  #gcloud container clusters create CLUSTER --workload-pool=PROJECT_ID.svc.id.goog
  gcloud container clusters get-credentials "$CLUSTER" --region="$REGION"
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
      --member "serviceAccount:$PROJECT_ID.svc.id.goog[$K8S_NAMESPACE/$KSA_NAME]"

  annotation=$(kubectl get serviceaccount $KSA_NAME -o jsonpath='{.metadata.annotations.iam\.gke\.io\/gcp-service-account}')
  if [ -z "$annotation" ]; then
    kubectl annotate serviceaccount $KSA_NAME \
        --namespace $K8S_NAMESPACE \
        iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com
  else
    $print "Annotation already exists - $annotation" INFO
  fi
  kubectl describe serviceaccount $KSA_NAME
}

create_CDS_Library_zip

configure_cloud_build

enable_project_apis

setup_network

setup_cluster

#Assign Workload Identity https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubectl

create_CDS_Library_zip

create_bucket

create_gservice_account

create_kservice_account

configure_kservice_account



