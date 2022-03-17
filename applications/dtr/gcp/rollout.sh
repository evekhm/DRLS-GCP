#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$GCP"/apply.sh
source "$GCP"/../bin/SET

if  kubectl get statefulset "$APPLICATION" --ignore-not-found=true  -n "$KUBE_NAMESPACE" | grep "$APPLICATION"; then
  echo "Rolling out restart $APPLICATION..."
  kubectl rollout restart statefulset "$APPLICATION" -n "$KUBE_NAMESPACE"
fi
