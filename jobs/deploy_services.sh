#!/usr/bin/env bash
#
set -e # Exit if error is detected during pipeline execution
set -x

JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APPLICATIONS_DIR="$JOBS_DIR/../applications"
UTILS="$JOBS_DIR/../shared"
OUT_ENV=${VARIABLES_FILE}
OUT_ENV_tmp="$JOBS_DIR/tmp.env"

echo "Running  $(basename "$0") with KUBE_NAMESPACE=$KUBE_NAMESPACE, out $OUT_ENV "

if [ -f "$OUT_ENV" ]; then
  rm "$OUT_ENV"
fi

function deploy_service_ip_port(){
  local DD=$1
  source "$APPLICATIONS_DIR/$DD/bin/SET"
  kubectl apply -f "$APPLICATIONS_DIR/$DD/k8s/service.yaml" --namespace="$KUBE_NAMESPACE" &> /dev/null
  IP=$("$UTILS/get_service_external_ip_port" "$APPLICATION"-service)
  echo "$IP"
}

function deploy_service_ip(){
  local DD=$1
  source "$APPLICATIONS_DIR/$DD/bin/SET"
  kubectl apply -f "$APPLICATIONS_DIR/$DD/k8s/service.yaml" --namespace="$KUBE_NAMESPACE" &> /dev/null
  IP=$("$UTILS/get_service_external_ip" "$APPLICATION"-service)
  echo "$IP"
}

IP=$(deploy_service_ip_port auth)
printf "export AUTH=http://%s\n" "$IP" > "$OUT_ENV_tmp"
echo "Deployed AUTH=$IP"

IP=$(deploy_service_ip_port crd)
printf "export CRD=http://%s\n" "$IP" >> "$OUT_ENV_tmp"
echo "Deployed CRD=$IP"

IP=$(deploy_service_ip_port dtr)
printf "export DTR=http://%s\n" "$IP" >> "$OUT_ENV_tmp"
echo "Deployed DTR=$IP"

IP=$(deploy_service_ip_port test-ehr)
printf "export TEST_EHR=http://%s\n" "$IP" >> "$OUT_ENV_tmp"
echo "Deployed TEST_EHR=$IP"

IP=$(deploy_service_ip crd-request-generator)
printf "export CRD_REQUEST_GENERATOR_HOST=http://%s\n" "$IP" >> "$OUT_ENV_tmp"
echo "Deployed CRD_REQUEST_GENERATOR_HOST=$IP"

IP=$(deploy_service_ip_port prior-auth)
printf "export PRIOR_AUTH=http://%s\n" "$IP" >> "$OUT_ENV_tmp"
echo "Deployed PRIOR_AUTH=$IP"

mv "$OUT_ENV_tmp" "$OUT_ENV"

echo "Generated $OUT_ENV with service IP parameters"
cat "$OUT_ENV"
unset APPLICATION


