#!/usr/bin/env bash
set -euo pipefail

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

thread_id="${CODEX_THREAD_ID:-}"
[[ -n "$thread_id" ]] || fail 'CODEX_THREAD_ID is not set.'
[[ "$thread_id" =~ ^[A-Za-z0-9-]+$ ]] || fail 'CODEX_THREAD_ID has an unexpected format.'
command -v rg >/dev/null 2>&1 || fail 'rg is not available.'

sessions_directory="${HOME}/.codex/sessions"
[[ -d "$sessions_directory" ]] || fail 'Codex sessions directory not found.'

rollout=''
latest_mtime=-1
while IFS= read -r candidate; do
    if mtime=$(stat -c '%Y' "$candidate" 2>/dev/null); then
        :
    elif mtime=$(stat -f '%m' "$candidate" 2>/dev/null); then
        :
    else
        continue
    fi
    if (( mtime > latest_mtime )); then
        rollout="$candidate"
        latest_mtime=$mtime
    fi
done < <(rg --files "$sessions_directory" -g "*${thread_id}*.jsonl")

[[ -n "$rollout" ]] || fail 'Rollout not found.'

if command -v jq >/dev/null 2>&1; then
    jq -Rsc '
        [split("\n")[] | fromjson? | select(.type == "turn_context")]
        | last
        | if . == null then
            error("turn_context not found.")
          else
            {model: .payload.model, effort: (.payload.effort // null)}
            | if .model == null or .model == "" then
                error("effective model not found.")
              else .
              end
          end
    ' "$rollout"

elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    if command -v python3 >/dev/null 2>&1; then
        python_command=python3
    else
        python_command=python
    fi

    "$python_command" - "$rollout" <<'PY'
import json
import sys

latest = None

with open(sys.argv[1], encoding="utf-8") as f:
    for line in f:
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue

        if record.get("type") == "turn_context":
            latest = record

if latest is None:
    raise SystemExit("turn_context not found.")

payload = latest.get("payload") or {}
model = payload.get("model")

if not model:
    raise SystemExit("effective model not found.")

print(json.dumps({
    "model": model,
    "effort": payload.get("effort"),
}, separators=(",", ":")))
PY

elif command -v osascript >/dev/null 2>&1; then
    osascript -l JavaScript - "$rollout" <<'JXA'
ObjC.import("Foundation");

function run(argv) {
    const path = argv[0];
    const text = $.NSString
        .stringWithContentsOfFileEncodingError(
            path,
            $.NSUTF8StringEncoding,
            null
        ).js;

    let latest = null;

    for (const line of text.split(/\r?\n/)) {
        if (!line.trim()) continue;

        try {
            const record = JSON.parse(line);
            if (record.type === "turn_context") {
                latest = record;
            }
        } catch (_) {}
    }

    if (!latest) {
        throw new Error("turn_context not found.");
    }

    const payload = latest.payload || {};

    if (!payload.model) {
        throw new Error("effective model not found.");
    }

    return JSON.stringify({
        model: payload.model,
        effort: payload.effort == null ? null : payload.effort
    });
}
JXA

else
    fail 'No JSON parser is available (jq, python, or macOS osascript).'
fi
