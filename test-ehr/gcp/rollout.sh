#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP"/../bin
"$GCP"/../../shared/rollout "$BIN" "$GCP"