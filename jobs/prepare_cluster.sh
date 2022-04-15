#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
#Expects following env to be set:
# KUBE_NAMESPACE, KSA_NAME, GSA_NAME, PROJECT_ID, SECRET, CI_DEPLOY_USER, CI_DEPLOY_PASSWORD

JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
print="$JOBS_DIR/../shared/print"
GSA_EMAIL=$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com

#echo SERVICE_ACCOUNT_FILE="$SERVICE_ACCOUNT_FILE"

#Pre-pare steps:
# 1. Each deployment has its own IP assigned to services, following steps are deployment specific:
# Deploy services, because those IP are needed for Deployments
# Build and deploy keycloak, because it has IP address built in the Image of the service

# 2. Project-ID specific steps
# Service Account required for CRD to access Cloud Storage (with CQL rules)

#KUBE_NAMESPACE specific steps
# Create KSA Service account and Workload Identity required for CRD application to access Cloud Storage

echo "$(basename "$0") KUBE_NAMESPACE=$KUBE_NAMESPACE PROJECT_ID=$PROJECT_ID "
# begin ----------- KUBE_NAMESPACE specific -----------
create_kservice_account(){
  $print "Preparing KSA service account [$KSA_NAME] in [$KUBE_NAMESPACE] namespace ..."
  if kubectl get serviceaccounts --namespace "$KUBE_NAMESPACE" | grep "$KSA_NAME"; then
    $print "Kubernetes Service account [$KSA_NAME] has been found." INFO
  else
    $print "Creating kubernetes service account [$KSA_NAME]..." INFO
    kubectl create serviceaccount "$KSA_NAME" \
        --namespace "$KUBE_NAMESPACE"
  fi
}

# Done by GitLab CI/CD template
create_secret() {
    echo "Creating secret $SECRET in namespace $KUBE_NAMESPACE required for private repository access"
    if kubectl get secrets --namespace="$KUBE_NAMESPACE" | grep $SECRET; then
      echo "$SECRET exists in namespace $KUBE_NAMESPACE, skipping..."
    else
      echo "Logging into $CI_REGISTRY with deploy token $CI_DEPLOY_USER"
      docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
      kubectl create secret generic $SECRET --from-file=.dockerconfigjson=$HOME/.docker/config.json --type=kubernetes.io/dockerconfigjson --namespace=$KUBE_NAMESPACE
      kubectl get secrets --namespace="$KUBE_NAMESPACE" | grep $SECRET
    fi
}

# end ----------- KUBE_NAMESPACE specific -----------

# begin ----------- PROJECT-ID specific -----------
create_gservice_account() {
  $print "Preparing GSA service account [$GSA_NAME] ..."

  # shellcheck disable=SC2153
  if gcloud iam service-accounts list --filter="EMAIL=$GSA_EMAIL" --project "$PROJECT_ID" | grep "$GSA_EMAIL"; then
    $print "Service account [$GSA_EMAIL] has been found." INFO
  else
    $print "Creating service account [$GSA_NAME] ..." INFO
    gcloud iam service-accounts create "$GSA_NAME" \
        --description="Runs priorauth jobs" \
        --display-name="priorauth-service-account" \
        --project="${PROJECT_ID}"
  fi
  echo "Created service account [$GSA_NAME]"
  #gcloud iam service-accounts get-iam-policy $GSA_EMAIL

}

configure_kservice_account(){
  $print "Configuring KSA [$KSA_NAME]..."
#  echo "Creating Binding .... "
#  echo "gcloud iam service-accounts add-iam-policy-binding $GSA_EMAIL \
#              --role roles/iam.workloadIdentityUser \
#              --member "serviceAccount:$PROJECT_ID.svc.id.goog[$KUBE_NAMESPACE/$KSA_NAME]""
#  echo "Check that $GSA_EMAIL exists:"
#  gcloud iam service-accounts describe $GSA_EMAIL

  gcloud iam service-accounts add-iam-policy-binding "$GSA_EMAIL" \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:$PROJECT_ID.svc.id.goog[$KUBE_NAMESPACE/$KSA_NAME]"

  echo "Creating annotation ..."

  kubectl get serviceaccount "$KSA_NAME" --namespace "$KUBE_NAMESPACE"

  annotation=$(kubectl get serviceaccount "$KSA_NAME" --namespace "$KUBE_NAMESPACE" -o jsonpath='{.metadata.annotations.iam\.gke\.io\/gcp-service-account}')
  echo "Annotation in the namespace [$KUBE_NAMESPACE] = $annotation"

  if [ -z "$annotation" ]; then
    kubectl annotate serviceaccount $KSA_NAME \
        --namespace "$KUBE_NAMESPACE" \
        iam.gke.io/gcp-service-account=$GSA_NAME@"$PROJECT_ID".iam.gserviceaccount.com
  else
    $print "Annotation already exists - $annotation" INFO
  fi
  echo "Almost at the end...."
  kubectl describe serviceaccount $KSA_NAME --namespace "$KUBE_NAMESPACE"
}
# end ----------- PROJECT-ID specific -----------

if [ -n "$KUBE_NAMESPACE" ]; then kubectl get namespace "$KUBE_NAMESPACE" 2>/dev/null || kubectl create namespace "$KUBE_NAMESPACE"; fi

create_secret

#Assign Workload Identity https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubectl

create_gservice_account

create_kservice_account

configure_kservice_account


"${JOBS_DIR}"/deploy_services.sh