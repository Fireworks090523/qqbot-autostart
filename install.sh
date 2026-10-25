#!/bin/bash
# 安装 qqbot-autostart 到当前 DSH profile
set -u
SRC="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="${DSH_HOME:-/root/.dsh}"
PROFILE="${DSH_PROFILE:-web}"
PROF_DIR="$HOME_DIR/profiles/$PROFILE"
NAME="qqbot-autostart"

[ -f "$PROF_DIR/package.json" ] || { echo "❌ 找不到 $PROF_DIR/package.json"; exit 1; }

# 1) 复制插件本体到 HOME_DIR 下（保持稳定路径，别指向解压目录）
DEST="$HOME_DIR/$NAME"
mkdir -p "$DEST/lib"
cp -f "$SRC/package.json" "$SRC/cordis.patch.yml" "$DEST/" 2>/dev/null
cp -f "$SRC/lib/index.js" "$DEST/lib/"
echo "✅ 插件已放到 $DEST"

# 2) 注册依赖 + bundle
python3 - "$PROF_DIR/package.json" "$DEST" "$NAME" <<'PY'
import json, sys
p, dest, name = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(p))
d.setdefault('dependencies', {})[name] = 'link:' + dest
prof = d.setdefault('dsh', {}).setdefault('profile', {})
b = prof.setdefault('bundles', [])
if name not in b:
    b.append(name)
json.dump(d, open(p, 'w'), ensure_ascii=False, indent=2)
print('✅ 已写入 bundles:', b[-3:])
PY

# 3) 软链
ln -sfn "$DEST" "$PROF_DIR/node_modules/$NAME"
echo "✅ 软链: $PROF_DIR/node_modules/$NAME -> $DEST"

# 4) 语法自检
node --input-type=module -e "import('$DEST/lib/index.js').then(m=>{if(typeof m.apply!=='function')throw new Error('no apply');console.log('✅ 插件可加载，apply 正常')}).catch(e=>{console.error('❌ 加载失败:',e.message);process.exit(1)})" || exit 1

echo
echo "完成。现在："
echo "  1) 重启 App（插件在 DSH 启动时加载）"
echo "  2) 25 秒后看日志: cat ${QQBOT_LOG:-/root/qq-bot/autostart.log}"
echo "  3) 想临时关掉: touch $HOME_DIR/$NAME.off"
