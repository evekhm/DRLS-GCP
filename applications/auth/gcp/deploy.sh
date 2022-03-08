#!/usr/bin/env bash
GCP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILS="$GCP"/../../../shared
BIN="$GCP"/../bin

"$UTILS"/deploy "$BIN" "$GCP"