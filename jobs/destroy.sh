#!/usr/bin/env bash

echo "Current context: $(kubectl config current-context) "

read -r -p "Are you sure you want to remove namespace=$KUBE_NAMESPACE? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]];
then
    kubectl delete all --all -n "$KUBE_NAMESPACE"
else
    exit
fi

#Delete end points
for i in $(gcloud endpoints services list --format="value(NAME)"); do gcloud endpoints services delete "$i" --async --quiet; done

#Delete reserved IP addresses
for i in $(gcloud compute addresses list --global --format "value(name)"); do gcloud compute addresses delete "$i" --quiet --global; done

