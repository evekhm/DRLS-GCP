#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
source "$DIR"/../bin/SET

function getExternalIp() {
  IP=$(kubectl get service "$APPLICATION" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

"$DIR"/../bin/docker_build

docker push "$IMAGE"

"$DIR"/apply.sh

getExternalIp
while [ -z "$IP" ]
do
   echo "Waiting for external IP to get assigned to the service $APPLICATION...."
   sleep 10
   getExternalIp
done
echo "External IP for $APPLICATION is $IP"

cd "$PWD" || exit


