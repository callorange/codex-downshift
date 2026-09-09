$ErrorActionPreference = 'Stop'

$threadId = $env:CODEX_THREAD_ID
if (-not $threadId) { throw 'CODEX_THREAD_ID is not set.' }
if ($threadId -notmatch '^[A-Za-z0-9-]+$') { throw 'CODEX_THREAD_ID has an unexpected format.' }
if (-not (Get-Command rg -ErrorAction SilentlyContinue)) { throw 'rg is not available.' }

$sessionsDirectory = Join-Path $HOME '.codex\sessions'
if (-not (Test-Path -LiteralPath $sessionsDirectory -PathType Container)) {
    throw 'Codex sessions directory not found.'
}

$rollout = rg --files $sessionsDirectory -g "*$threadId*.jsonl" |
    ForEach-Object { Get-Item -LiteralPath $_ } |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
if (-not $rollout) { throw 'Rollout not found.' }

$latest = Get-Content -Encoding UTF8 -LiteralPath $rollout.FullName |
    ForEach-Object { try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null } } |
    Where-Object { $_.type -eq 'turn_context' } |
    Select-Object -Last 1
if (-not $latest) { throw 'turn_context not found.' }

$model = $latest.payload.model
if (-not $model) { throw 'effective model not found.' }

[pscustomobject]@{
    model  = $model
    effort = $latest.payload.effort
} | ConvertTo-Json -Compress
