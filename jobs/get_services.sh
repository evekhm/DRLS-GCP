#!/usr/bin/env bash

set -e # Exit if error is detected during pipeline execution
JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APPLICATIONS_DIR="$JOBS_DIR/../applications"
UTILS="$JOBS_DIR/../shared"

while getopts o: flag
do
    case "${flag}" in
        o) OUT_ENV=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

if [ -z "$OUT_ENV" ]; then
  OUT_ENV=${VARIABLES_FILE}
fi

if [ -f "$OUT_ENV" ]; then
  rm "$OUT_ENV"
fi
OUT_ENV_tmp="${OUT_ENV}.tmp"

function get_service_ip_port(){
  local DD=$1
  source "$APPLICATIONS_DIR/$DD/bin/SET"
  IP=$("$UTILS/get_service_external_ip_port" "$APPLICATION"-service)
  echo "$IP"
}

function get_service_ip(){
  local DD=$1
  source "$APPLICATIONS_DIR/$DD/bin/SET"
  IP=$("$UTILS/get_service_external_ip" "$APPLICATION"-service)
  echo "$IP"
}

echo APPLICATION=$APPLICATION
unset APPLICATION
printf "export AUTH=http://%s\n" "$(get_service_ip_port auth)" > "$OUT_ENV_tmp"
cat "$OUT_ENV_tmp"
get_service_ip_port auth

unset APPLICATION
printf "export CRD=http://%s\n" "$(get_service_ip_port crd)" >> "$OUT_ENV_tmp"
cat "$OUT_ENV_tmp"
get_service_ip_port crd

unset APPLICATION
printf "export DTR=http://%s\n" "$(get_service_ip_port dtr)" >> "$OUT_ENV_tmp"
cat "$OUT_ENV_tmp"
get_service_ip_port dtr

unset APPLICATION
printf "export TEST_EHR=http://%s\n" "$(get_service_ip_port test-ehr)" >> "$OUT_ENV_tmp"
cat "$OUT_ENV_tmp"
get_service_ip_port test-ehr

unset APPLICATION
printf "export PRIOR_AUTH=http://%s\n" "$(get_service_ip_port prior-auth)" >> "$OUT_ENV_tmp"
cat "$OUT_ENV_tmp"
get_service_ip_port prior-auth

printf "export CRD_REQUEST_GENERATOR_HOST=http://%s\n" "$(get_service_ip crd-request-generator)" >> "$OUT_ENV_tmp"
cat "$OUT_ENV_tmp"
get_service_ip_port crd-request-generator

mv "$OUT_ENV_tmp" "$OUT_ENV"

echo "Generated $OUT_ENV with service IP parameters"
cat "$OUT_ENV"

unset APPLICATION
#"$DIR/print_steps.sh"


