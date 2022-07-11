set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PROJECT_ID=$(gcloud config get-value project 2> /dev/null);
if [ -z "$PROJECT_ID" ]; then
  echo "Make sure active configuration has PROJECT set" 'ERROR'
  exit 1
fi

echo "======= Running  $(basename "$0") with KUBE_NAMESPACE=$KUBE_NAMESPACE ======="

function create_endpoint(){
  K8S_NAME=$1
  FQDN=$2
  K8S_SERVICE_PORT=$3
  PATH_1=$4  #optional
  K8S_SERVICE_PORT_2=$5 #optional
  PATH_2=$6 #optional

  if [[ $# -eq 6 ]]; then
    echo "Ingress for multiple $K8S_NAME service ports: ${K8S_SERVICE_PORT} with path ${PATH_1} and ${K8S_SERVICE_PORT_2} with path ${PATH_2} will be initiated"
    INGRESS2='true'
  fi

  K8S_INGRESS=${K8S_NAME}-ingress
  K8S_INGRESS_IP_NAME=${K8S_NAME}-${KUBE_NAMESPACE}-ip
  K8S_CERTIFICATE=${K8S_NAME}-certificate
  NETWORK=${NETWORK:-default}
  K8S_NAMESPACE=${KUBE_NAMESPACE:-default}
  if [ -z "$K8S_SERVICE_PORT_2" ]; then
    PORTS=tcp:${K8S_SERVICE_PORT}
  else
    PORTS=tcp:${K8S_SERVICE_PORT},tcp:${K8S_SERVICE_PORT_2}
  fi


  echo "*************** Creating managedCert and Endpoints for SERVICE=$K8S_NAME, PORT=$K8S_SERVICE_PORT, FQDN=$FQDN ***************"
  FW_RULE_NAME=${NETWORK}-${K8S_NAME}-allow-lb-healthchecks


  if gcloud compute firewall-rules list \
  --filter="name=( \"$FW_RULE_NAME\" ) AND network=( \"https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/networks/$NETWORK\" )" --format=json | grep $FW_RULE_NAME; then
    echo "firewall already exists for ${K8S_SERVICE_PORT} ${K8S_SERVICE_PORT_2} in $NETWORK network"
  else
    echo "Creating firewall rule ${FW_RULE_NAME}"
    gcloud compute firewall-rules create "${FW_RULE_NAME}" \
        --allow ${PORTS}  --source-ranges=35.191.0.0/16,130.211.0.0/22 \
        --network ${NETWORK}
  fi

  if gcloud compute addresses list --format="value(NAME)"  --project=$PROJECT_ID | grep "$K8S_INGRESS_IP_NAME"; then
    echo "Already reserved External IP $K8S_INGRESS_IP_NAME"
  else
    echo "Reserving External IP $K8S_INGRESS_IP_NAME"
    gcloud compute addresses create "$K8S_INGRESS_IP_NAME" --global
  fi

  K8S_INGRESS_IP=$(gcloud compute addresses describe "$K8S_INGRESS_IP_NAME" --global --format="value(address)")
  echo K8S_INGRESS_IP=$K8S_INGRESS_IP

# Map the FQDN to the IP address
cat <<EOF > ${K8S_NAME}-openapi.yaml
swagger: "2.0"
info:
  description: "$K8S_NAME"
  title: "$K8S_NAME"
  version: "1.0.0"
host: "${FQDN}"
x-google-endpoints:
- name: "${FQDN}"
  target: "$K8S_INGRESS_IP"
paths: {}

EOF

gcloud endpoints services deploy ${K8S_NAME}-openapi.yaml
rm ${K8S_NAME}-openapi.yaml


cat <<EOF | kubectl apply -n $K8S_NAMESPACE -f -
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: ${K8S_CERTIFICATE}
spec:
  domains:
    - ${FQDN}
EOF

# ingress
  if [ -z "$INGRESS2" ]; then
cat <<EOF | kubectl apply -n $K8S_NAMESPACE -f -
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: ${K8S_INGRESS}-frontend-config
spec:
  redirectToHttps:
    enabled: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${K8S_INGRESS}
  annotations:
    networking.gke.io/v1beta1.FrontendConfig: ${K8S_INGRESS}-frontend-config
    kubernetes.io/ingress.global-static-ip-name: ${K8S_INGRESS_IP_NAME}
    networking.gke.io/managed-certificates: ${K8S_CERTIFICATE}
    kubernetes.io/ingress.class: "gce"
spec:
  defaultBackend:
    service:
      name: ${K8S_NAME}
      port:
        number: ${K8S_SERVICE_PORT}
EOF
  else
cat <<EOF | kubectl apply -n $K8S_NAMESPACE -f -
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: ${K8S_INGRESS}-frontend-config
spec:
  redirectToHttps:
    enabled: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${K8S_INGRESS}
  annotations:
    networking.gke.io/v1beta1.FrontendConfig: ${K8S_INGRESS}-frontend-config
    kubernetes.io/ingress.global-static-ip-name: ${K8S_INGRESS_IP_NAME}
    networking.gke.io/managed-certificates: ${K8S_CERTIFICATE}
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: ${K8S_NAME}
            port:
              number: ${K8S_SERVICE_PORT}
        path: ${PATH_1}
        pathType: ImplementationSpecific
      - backend:
          service:
            name: ${K8S_NAME}
            port:
              number: ${K8S_SERVICE_PORT_2}
        path: ${PATH_2}
        pathType: ImplementationSpecific
EOF
  fi
  echo "Deployed $FQDN end point"

}

create_cert(){
  SVC_HOST=$1
  NAME=tls-config
  echo "Creating self-signed certificate for host " "$SVC_HOST"
#  openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -subj \
#      "/CN=${SVC_HOST}" \
#      -addext "subjectAltName = DNS:localhost,DNS:${SVC_HOST}" \
#      -out "tls.crt" -keyout "tls.key"

  openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -subj \
      "/CN=auth.endpoints.rosy-resolver-348520.cloud.goog" \
      -out "tls.crt" -keyout "tls.key"

  if kubectl get secrets --namespace="$KUBE_NAMESPACE" | grep $NAME; then
    echo "$NAME exists in namespace $KUBE_NAMESPACE, skipping..."
  else
    kubectl create secret tls $NAME --cert=tls.crt  --key=tls.key --namespace="$KUBE_NAMESPACE"
  fi
  rm tls.crt
  rm tls.key

}

source "$DIR/../shared/.endpoints"
create_endpoint auth-service "$AUTH_EP" 80
create_cert "$AUTH_EP"
create_endpoint crd-service "$CRD_EP" 8090
create_endpoint dtr-service "$DTR_EP" 3005
create_endpoint prior-auth-service "$PRIOR_AUTH_EP" 9000
create_endpoint test-ehr-service "$TEST_EHR_EP" 8080
create_endpoint crd-request-generator-service "$CRD_REQUEST_GENERATOR_EP" 80 "/*" 3001 "/public_keys" -n emr

kubectl get managedcertificates -n "$K8S_NAMESPACE"
gcloud endpoints services list | grep  "$K8S_NAMESPACE"
gcloud compute addresses list | grep  "$K8S_NAMESPACE"
kubectl get ingress -n "$K8S_NAMESPACE"