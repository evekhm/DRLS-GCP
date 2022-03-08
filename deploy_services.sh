#!/usr/bin/env bash
#
set -e # Exit if error is detected during pipeline execution
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR/bin"
OUT_ENV="$DIR/.env"
OUT_ENV_tmp="$DIR/tmp.env"

if [ -f "$OUT_ENV" ]; then
  rm "$OUT_ENV"
fi

function deploy_service_ip_port(){
  DD=$1
  source "$DIR/applications/$DD/bin/SET"
  kubectl apply -f "$DIR/applications/$DD/k8s/service.yaml" --namespace="$KUBE_NAMESPACE" &> /dev/null
  IP=$("$UTILS/get_service_external_ip_port" "$APPLICATION"-service)
  echo "$IP"
}

function deploy_service_ip(){
  DD=$1
  source "$DIR/applications/$DD/bin/SET"
  kubectl apply -f "$DIR/applications/$DD/k8s/service.yaml" --namespace="$KUBE_NAMESPACE" &> /dev/null
  IP=$("$UTILS/get_service_external_ip" "$APPLICATION"-service)
  echo "$IP"
}

echo "Deploying Services ..."

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




