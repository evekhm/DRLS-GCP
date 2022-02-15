#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
#Expects: KUBE_NAMESPACE, KSA_NAME, GSA_NAME, PROJECT_ID


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR"/shared
print="$UTILS/print"

echo "Using Project_ID=$PROJECT_ID, KUBE_NAMESPACE=$KUBE_NAMESPACE, KSA_NAME=$KSA_NAME, GSA_NAME=$GSA_NAME"

create_namespace(){
  if kubectl get namespaces | grep "$KUBE_NAMESPACE"; then
    $print "[$KUBE_NAMESPACE] namespace already exists" INFO
  else
    $print "Creating [$KUBE_NAMESPACE] namespace" INFO
    kubectl create namespace "$KUBE_NAMESPACE"
  fi
}

create_kservice_account(){
  $print "Preparing KSA service account [$KSA_NAME] in [$KUBE_NAMESPACE] namespace ..."
  if kubectl get serviceaccounts --namespace "$KUBE_NAMESPACE" | grep -q "$KSA_NAME"; then
    $print "Kubernetes Service account [$KSA_NAME] has been found." INFO
  else
    $print "Creating kubernetes service account [$KSA_NAME]..." INFO
    kubectl create serviceaccount "$KSA_NAME" \
        --namespace "$KUBE_NAMESPACE"
  fi
}


create_gservice_account() {
  $print "Preparing GSA service account [$GSA_NAME] ..."

  # shellcheck disable=SC2153
  if gcloud iam service-accounts list --project "$PROJECT_ID" | grep -q "$GSA_NAME"; then
    $print "Service account [$GSA_NAME] has been found." INFO
  else
    $print "Creating service account [$GSA_NAME] ..." INFO
    gcloud iam service-accounts create "$GSA_NAME" \
        --description="Runs priorauth jobs" \
        --display-name="priorauth-service-account" \
        --project="${PROJECT_ID}"
  fi

  echo "Created service account [$GSA_NAME]"
  gcloud iam service-accounts get-iam-policy \
      $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

}

configure_kservice_account(){
  $print "Configuring KSA [$KSA_NAME]..."
  gcloud iam service-accounts describe $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com
  gcloud iam service-accounts add-iam-policy-binding $GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:$PROJECT_ID.svc.id.goog[$KUBE_NAMESPACE/$KSA_NAME]"

  annotation=$(kubectl get serviceaccount $KSA_NAME -o jsonpath='{.metadata.annotations.iam\.gke\.io\/gcp-service-account}')
  echo "Annotation = $annotation"

  if [ -z "$annotation" ]; then
    kubectl annotate serviceaccount $KSA_NAME \
        --namespace $KUBE_NAMESPACE \
        iam.gke.io/gcp-service-account=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com
  else
    $print "Annotation already exists - $annotation" INFO
  fi
  kubectl describe serviceaccount $KSA_NAME --namespace $KUBE_NAMESPACE
}

create_namespace

#Assign Workload Identity https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubectl

create_gservice_account

create_kservice_account

configure_kservice_account




