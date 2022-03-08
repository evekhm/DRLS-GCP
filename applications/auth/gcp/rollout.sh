#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$GCP/../bin"
UTILS="$GCP"/../../shared

"$UTILS"/rollout "$BIN" "$GCP"