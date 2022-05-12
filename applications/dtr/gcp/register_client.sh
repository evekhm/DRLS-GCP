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
  --data-raw "{\"name\":\"app-login\",\"client\":\"$TEST_EHR/test-ehr/r4\"}" \
  --compressed
