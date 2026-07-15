#!/usr/bin/env bash
# Bash equivalent of:
#   Import-Module .\Merge-SysmonXml.ps1
#   Merge-AllSysmonXml -Path (Get-ChildItem '[0-9]*\*.xml') -AsString | Out-File sysmonconfig.xml -Encoding ascii
#
# Merge-SysmonXml.ps1 requires pwsh, which isn't installed on this machine. This repo
# already ships a documented cross-platform equivalent (merge_sysmon_configs.py, README
# "Python generator tool" section) driven by a CSV file list + priority instead of a
# folder scan. This script just wraps that documented invocation for repeatable use.
#
# Usage: ./merge-sysmon-config.sh [list.csv] [template.xml] [outfile.xml]

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

LIST="${1:-config_lists/default_list/default_list.csv}"
TEMPLATE="${2:-templates/sysmon_template.xml}"
OUT="${3:-sysmonconfig.xml}"

python3 merge_sysmon_configs.py "$LIST" -f csv -b "$TEMPLATE" -o "$OUT"
echo "Wrote $OUT"
