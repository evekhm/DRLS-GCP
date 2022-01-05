#!/usr/bin/env bash

PROJECT_ID=$(gcloud config get-value project 2> /dev/null);
REGION='us-central1'
CLUSTER='prior-auth-cluster'
APPLICATION='keycloak'

function getExternalIp() {
  IP=$(kubectl get service $APPLICATION -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"
kubectl apply -f k8s

getExternalIp
while [ -z "$IP" ]
do
   echo "Waiting for external IP to get assigned to the service $APPLICATION...."
   sleep 10
   getExternalIp
done


echo "External IP for $APPLICATION is $IP"
