#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$GCP"/apply.sh
source "$GCP"/../bin/SET
echo "Rolling Out $APPLICATION..."
kubectl rollout restart statefulset "$APPLICATION"