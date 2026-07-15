#!/usr/bin/env bash
# Repo-side stand-in for the Windows validation step recommended at the end of the
# conversation this script was derived from:
#
#   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1000 |
#     Where-Object {$_.Id -eq 10} | Measure-Object
#
# That command reads live Sysmon telemetry from a running Windows endpoint's event log,
# which does not exist on this machine (this checkout is just the config source, not a
# monitored Windows host). It CANNOT be reproduced here even in bash -- there is no bash
# equivalent for "count live Sysmon Event 10s on this box" because this box never
# generates any.
#
# What this script does instead: confirms, inside the generated sysmonconfig.xml itself,
# that the new exclude actually merged in, and reports how the ProcessAccess exclude
# rule-group and the T1036/Masquerading tag count (same grep matrix-build.yml uses)
# changed vs the last committed config. Run the real Get-WinEvent before/after check on
# the actual Windows agent (e.g. gafo-vm) once sysmonconfig.xml is deployed there.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

CONFIG="${1:-sysmonconfig.xml}"

echo "== Checking $CONFIG for the VS Code ProcessAccess exclude =="
if grep -qF 'Microsoft VS Code\Code.exe' "$CONFIG" 2>/dev/null; then
    echo "OK: VS Code exclude rule present in $CONFIG"
else
    echo "MISSING: VS Code exclude rule not found in $CONFIG"
fi

echo
echo "== T1036 (Masquerading) tag count: committed HEAD vs working tree =="
if git rev-parse --verify HEAD >/dev/null 2>&1 && git cat-file -e "HEAD:$CONFIG" 2>/dev/null; then
    before=$(git show "HEAD:$CONFIG" | grep -o 'technique_id=T1036' | wc -l)
else
    before="n/a (no committed baseline)"
fi
after=$(grep -o 'technique_id=T1036' "$CONFIG" | wc -l)
echo "before: $before"
echo "after:  $after"

echo
echo "== ProcessAccess exclude RuleGroup child-rule count =="
python3 - "$CONFIG" <<'EOF'
import sys
from lxml import etree

tree = etree.parse(sys.argv[1])
for pa in tree.findall(".//RuleGroup/ProcessAccess[@onmatch='exclude']"):
    print(f"{len(pa)} child rules/conditions in this exclude group")
EOF
