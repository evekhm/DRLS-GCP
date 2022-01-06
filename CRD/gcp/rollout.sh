#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
source "$GCP"/../bin/SET

"$GCP"/apply.sh

echo 'Rolling Out Deployment'
kubectl rollout restart deployment crd