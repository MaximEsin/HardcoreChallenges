# Собирает zip для загрузки на CurseForge / WoWInterface и т.п.
# Без .git, __MACOSX, ._*, .vscode / .cursor (не попадают в «blacklisted»).
$ErrorActionPreference = "Stop"

$AddonRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Name = Split-Path $AddonRoot -Leaf
$Toc = Join-Path $AddonRoot "$Name.toc"

$Version = "unknown"
if (Test-Path $Toc) {
    $line = Get-Content $Toc | Where-Object { $_ -match '^\s*## Version:' } | Select-Object -First 1
    if ($line) {
        $Version = ($line -replace '^\s*## Version:\s*', '').Trim()
    }
}
if ($Version -eq "unknown") {
    Write-Warning "Could not read ## Version from $Toc, using 'unknown'."
}

$ExcludeNames = @('.git', '.DS_Store', '__MACOSX', '.vscode', '.cursor', '.agent-transcripts', 'CLAUDE_SPEC.md', 'scripts')

$Stage = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
$StageAddon = Join-Path $Stage $Name
New-Item -ItemType Directory -Path $StageAddon | Out-Null

try {
    Get-ChildItem -Path $AddonRoot -Force | Where-Object {
        $ExcludeNames -notcontains $_.Name -and $_.Name -notlike '._*'
    } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $StageAddon -Recurse -Force
    }

    $Out = Join-Path $AddonRoot "$Name-$Version-release.zip"
    if (Test-Path $Out) { Remove-Item $Out -Force }
    # remove legacy unversioned zip if present
    $Legacy = Join-Path $AddonRoot "$Name-release.zip"
    if (Test-Path $Legacy) { Remove-Item $Legacy -Force }

    Compress-Archive -Path $StageAddon -DestinationPath $Out -Force

    Write-Output "Created: $Out (version $Version from .toc)"
    Write-Output "Inside: one folder `"$Name/`" with $Name.toc at top level."
}
finally {
    Remove-Item -Recurse -Force $Stage -ErrorAction SilentlyContinue
}
