#!/usr/bin/env bash

# To Be Provisioned by DTP
set -e # Exit if error is detected during pipeline execution

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$DIR"/shared
print="$UTILS/print"

setup_network(){
  network=$(gcloud compute networks list --filter="name=( $NETWORK )" --format='get(NAME)' 2>/dev/null)
  if [ -z "$network" ]; then
      $print "Setting up [$NETWORK] network... "
      gcloud compute networks create "$NETWORK" --project="$PROJECT_ID" \
      --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional
      gcloud compute firewall-rules create default-allow-internal-"$NETWORK" --project="$PROJECT_ID" \
            --network=projects/"$PROJECT_ID"/global/networks/"$NETWORK" \
            --description=Allows\ connections\ from\ any\ source\ in\ the\ network\ IP\ range\ to\ any\ instance\ on\ the\ network\ using\ all\ protocols. \
            --direction=INGRESS --priority=65534 --source-ranges=10.128.0.0/9 --action=ALLOW --rules=all
  fi
}

setup_cluster() {
  $print "Setting up [$CLUSTER] cluster..."
  if gcloud container clusters list --region="$REGION" --format "value(NAME)" | grep "$CLUSTER" > /dev/null;
  then
    $print "Cluster [$CLUSTER] already up and running in [$REGION]" INFO
  else
    $print "Creating  [$CLUSTER] cluster in [$REGION] region..." INFO
    gcloud container clusters create-auto "$CLUSTER" \
        --region "$REGION" \
        --network "$NETWORK" \
        --project="$PROJECT_ID"
  fi

  #gcloud container clusters create CLUSTER --workload-pool=PROJECT_ID.svc.id.goog
  gcloud container clusters get-credentials "$CLUSTER" --region="$REGION" --project "$PROJECT_ID"
}

setup_network

setup_cluster


