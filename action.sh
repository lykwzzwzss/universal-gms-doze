#!/system/bin/sh

[ "$(id -u)" = 0 ] || { echo "需要 Root 权限。"; exit 1; }
MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || { echo "模块文件不完整，已取消。"; exit 1; }
. "$MODDIR/common.sh"
CURRENT_USER=$(gms_timeout 10 am get-current-user 2>/dev/null) || { echo "无法查询当前用户，已取消。"; exit 1; }
case "$CURRENT_USER" in ''|*[!0-9]*) echo "无法确认当前用户，已取消。"; exit 1 ;; esac
GMS=com.google.android.gms
echo "可选操作：清除当前用户 $CURRENT_USER 的 Google Play 服务数据。"
echo "可能需要重新登录，推送令牌和本地状态将重建；不清理其他用户或工作资料。"
echo "音量上键：确认清理；音量下键：取消。30 秒未选择自动取消。"
KEY=$(gms_timeout 30 getevent -ql 2>/dev/null | awk '
  /KEY_VOLUMEUP[ \t]+DOWN/ {print "up"; exit}
  /KEY_VOLUMEDOWN[ \t]+DOWN/ {print "down"; exit}')
if [ "$KEY" != up ]; then
  echo "已取消，未清除任何数据。"
  exit 0
fi
CHECK_USER=$(gms_timeout 10 am get-current-user 2>/dev/null) || CHECK_USER=unknown
if [ "$CHECK_USER" != "$CURRENT_USER" ]; then
  echo "当前用户已变化，已取消，未清除数据。"
  exit 0
fi
echo "正在清理当前用户 $CURRENT_USER……"
RESULT=$(gms_timeout 60 pm clear --user "$CURRENT_USER" "$GMS" 2>&1)
STATUS=$?
# GNU 常见为 124，BusyBox 的 TERM 超时可能为 143，强制结束为 137。
if [ "$STATUS" = 124 ] || [ "$STATUS" = 137 ] || [ "$STATUS" = 143 ]; then
  echo "清理请求已超时，系统可能仍在处理；结果未知，请勿立即重复清理。"
  exit 1
fi
if [ "$STATUS" = 0 ] && [ "$RESULT" = Success ]; then
  echo "清理完成。"
else
  echo "清理失败：${RESULT:-系统未返回有效结果}"
  exit 1
fi
