#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD=$(pwd)
source "$DIR"/../bin/SET

"$DIR"/apply.sh

echo 'Rolling Out Deployment'
kubectl rollout restart deployment crd