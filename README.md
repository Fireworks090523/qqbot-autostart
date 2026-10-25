# qqbot-autostart

给 **DSH（DeepSeek Harness）** 用的自启插件：App 启动后自动把 QQ 机器人（NapCat + qq-bridge 那一套）拉起来。

> 解决一件事：**清后台/重启手机后，机器人不会自己回来**。装了这个插件，打开 App 就自动恢复，不用敲命令。

---

## 原理（30 秒看懂）

DSH 启动时会加载 profile 里的插件，并对每个插件调用一次 `apply()`。
本插件在 `apply()` 里：**延迟 25 秒 → 用 detached 方式执行你的启动脚本**。

- 延迟是为了等 DSH 端口就绪（启动脚本通常要把端口写进 bridge 配置）
- `detached + unref`：DSH 退出/重启不会带走这个子进程
- 启动脚本必须**幂等**（已经在线就跳过），重复触发无害

---

## 安装

```bash
# 1. 解压到任意目录（下面以 ~/qqbot-autostart 为例）
unzip qqbot-autostart-1.0.0.zip -d /root/qqbot-autostart-dist
# 2. 一键注册
bash /root/qqbot-autostart-dist/install.sh
# 3. 重启 App（插件在启动时加载）
```

`install.sh` 做的事：

1. 把插件目录注册为 `profiles/web` 的依赖（`link:<绝对路径>`）
2. 往 `dsh.profile.bundles` 数组末尾追加 `qqbot-autostart`
3. 在 `profiles/web/node_modules` 里建软链

---

## 配置

全部通过环境变量覆盖（不设就用默认值）：

| 变量 | 默认 | 说明 |
|---|---|---|
| `QQBOT_BOOT` | `/root/qq-bot/boot.sh` | 你的启动脚本 |
| `QQBOT_LOG` | `/root/qq-bot/autostart.log` | 执行日志 |
| `QQBOT_DELAY_MS` | `25000` | 延迟毫秒 |
| `QQBOT_OFF_FLAG` | `<DSH_HOME>/qqbot-autostart.off` | 开关文件 |

> 环境变量要在 **DSH 进程的环境里**才生效。手机 App 通常拿不到你 shell 的 export，
> 所以更实际的做法是直接改 `lib/index.js` 顶部的默认值。

---

## 使用

| 想做什么 | 怎么做 |
|---|---|
| 启用 | 正常打开 App，25 秒后自动跑 |
| **临时禁用** | `touch /root/.dsh/qqbot-autostart.off` |
| 恢复 | `rm /root/.dsh/qqbot-autostart.off` |
| 看它跑没跑 | `cat /root/qq-bot/autostart.log` |
| 卸载 | `bash uninstall.sh` 或手动删 bundles 里的条目 |

---

## 安全性

- 插件内**全程 try/catch**，任何异常都吞掉，绝不会让 DSH 启动失败
- 就算插件包本身加载出错，DSH 也只是打一行 `skipping profile bundle` 然后继续
- 只做一件事：`spawn` 一个脚本，不联网、不读文件内容、不改配置

---

## 卸载（手动版）

1. 编辑 `~/.dsh/profiles/web/package.json`：从 `dsh.profile.bundles` 里删掉 `"qqbot-autostart"`
2. `rm ~/.dsh/profiles/web/node_modules/qqbot-autostart`（软链）
3. 重启 App

---

## 兼容性

- 需要 DSH 的 profile 支持 `dsh.bundle.patch`（0.1.7 以上）
- 与任何「启动脚本 + 幂等」的组合都能用，不限于 QQ 机器人

MIT License
