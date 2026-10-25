#!/bin/bash
set -u
HOME_DIR="${DSH_HOME:-/root/.dsh}"
PROFILE="${DSH_PROFILE:-web}"
PROF_DIR="$HOME_DIR/profiles/$PROFILE"
NAME="qqbot-autostart"

python3 - "$PROF_DIR/package.json" "$NAME" <<'PY'
import json, sys
p, name = sys.argv[1], sys.argv[2]
d = json.load(open(p))
d.get('dependencies', {}).pop(name, None)
b = d.get('dsh', {}).get('profile', {}).get('bundles', [])
if name in b:
    b.remove(name)
json.dump(d, open(p, 'w'), ensure_ascii=False, indent=2)
print('✅ 已从 profile 移除')
PY

rm -f "$PROF_DIR/node_modules/$NAME"
echo "✅ 软链已删"
echo "重启 App 后生效。"
