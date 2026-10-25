/** DSH 启动后自动拉起 QQ 机器人（默认 /root/qq-bot/boot.sh）。
 *  任何异常都必须吞掉，绝不能拖死 DSH 启动。
 *
 *  可用环境变量覆盖（可选）：
 *    QQBOT_BOOT        启动脚本路径，默认 /root/qq-bot/boot.sh
 *    QQBOT_LOG         日志文件，默认 /root/qq-bot/autostart.log
 *    QQBOT_DELAY_MS    延迟毫秒，默认 25000（等 DSH 端口就绪）
 *    QQBOT_OFF_FLAG    开关文件，存在则跳过，默认 <DSH_HOME>/qqbot-autostart.off
 */
import { spawn } from 'node:child_process'
import { existsSync } from 'node:fs'
import { join } from 'node:path'

export const name = 'qqbot-autostart'

const HOME = process.env.DSH_HOME || '/root/.dsh'
const BOOT = process.env.QQBOT_BOOT || '/root/qq-bot/boot.sh'
const LOG = process.env.QQBOT_LOG || '/root/qq-bot/autostart.log'
const FLAG_OFF = process.env.QQBOT_OFF_FLAG || join(HOME, 'qqbot-autostart.off')
const DELAY_MS = Math.max(0, Number(process.env.QQBOT_DELAY_MS) || 25000)

function launch() {
  try {
    if (existsSync(FLAG_OFF)) return      // 开关：touch 这个文件即禁用
    if (!existsSync(BOOT)) return         // 没有启动脚本就不折腾
    const child = spawn('bash', ['-c', `bash "${BOOT}" >> "${LOG}" 2>&1`], {
      detached: true,
      stdio: 'ignore'
    })
    child.on('error', () => {})
    child.unref()
  } catch {
    /* 静默：自启失败不影响 DSH */
  }
}

export function apply() {
  try {
    const timer = setTimeout(launch, DELAY_MS)
    timer.unref?.()
  } catch {
    /* 静默 */
  }
}
