#!/usr/bin/env bash
set -u # This prevents running the script if any of the variables have not been set
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
  source "$DIR/$DD/bin/SET"
  kubectl apply -f "$DIR/$DD/k8s/service.yaml" &> /dev/null
  IP=$("$UTILS/get_service_external_ip_port" "$APPLICATION"-service)
  echo "$IP"
}

function deploy_service_ip(){
  DD=$1
  source "$DIR/$DD/bin/SET"
  kubectl apply -f "$DIR/$DD/k8s/service.yaml" &> /dev/null
  IP=$("$UTILS/get_service_external_ip" "$APPLICATION"-service)
  echo "$IP"
}


printf "export AUTH=http://%s\n" "$(deploy_service_ip_port auth)" > "$OUT_ENV_tmp"
printf "export CRD=http://%s\n" "$(deploy_service_ip_port CRD)" >> "$OUT_ENV_tmp"
printf "export DTR=http://%s\n" "$(deploy_service_ip_port dtr)" >> "$OUT_ENV_tmp"
printf "export TEST_EHR=http://%s\n" "$(deploy_service_ip_port test-ehr)" >> "$OUT_ENV_tmp"
printf "export CRD_REQUEST_GENERATOR_HOST=http://%s\n" "$(deploy_service_ip crd-request-generator)" >> "$OUT_ENV_tmp"
mv "$OUT_ENV_tmp" "$OUT_ENV"


echo "Generated $OUT_ENV with service IP parameters"
cat "$OUT_ENV"




