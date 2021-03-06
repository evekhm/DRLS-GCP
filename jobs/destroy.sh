#!/usr/bin/env bash

echo "Current context: $(kubectl config current-context) "

read -r -p "Are you sure you want to remove namespace=$KUBE_NAMESPACE? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]];
then
    kubectl delete all --all -n "$KUBE_NAMESPACE"
else
    exit
fi