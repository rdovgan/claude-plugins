#!/usr/bin/env bash
# SessionEnd: release the domain locks of this session and drop its markers.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
command -v jq >/dev/null 2>&1 || exit 0

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
qd_unlock_all "$sid"
data="$(qd_data_dir)"
rm -f "$data/start.$sid" "$data/shas.$sid"
exit 0
