GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$GCP"/../../../shared/SET.manual
source "$VARIABLES_FILE"

echo | openssl s_client -connect dtr.demo-manual.endpoints.rosy-resolver-348520.cloud.goog:443 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > cert.pem

# TODO check readiness of dtr and as soon as ready, register client
curl "$DTR/clients" \
  -H 'Accept: */*' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H "Origin: $DTR" \
  -H "Referer: $DTR/register" \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  --data-raw "{\"name\":\"$TEST_EHR/test-ehr/r4\",\"client\":\"app-login\"}" \
  --compressed
