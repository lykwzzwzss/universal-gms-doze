#!/system/bin/sh

[ "$(id -u)" = 0 ] || { echo "需要 Root 权限。"; exit 1; }
CURRENT_USER=$(am get-current-user 2>/dev/null)
case "$CURRENT_USER" in ''|*[!0-9]*) echo "无法确认当前用户，已取消。"; exit 1 ;; esac
GMS=com.google.android.gms
echo "可选操作：清除当前用户 $CURRENT_USER 的 Google Play 服务数据。"
echo "可能需要重新登录，推送令牌和本地状态将重建；不清理其他用户或工作资料。"
echo "音量上键：确认清理；音量下键：取消。30 秒未选择自动取消。"
KEY=$(timeout 30 getevent -ql 2>/dev/null | awk '
  /KEY_VOLUMEUP[ \t]+DOWN/ {print "up"; exit}
  /KEY_VOLUMEDOWN[ \t]+DOWN/ {print "down"; exit}')
if [ "$KEY" != up ]; then
  echo "已取消，未清除任何数据。"
  exit 0
fi
if [ "$(am get-current-user 2>/dev/null)" != "$CURRENT_USER" ]; then
  echo "当前用户已变化，已取消，未清除数据。"
  exit 0
fi
echo "正在清理当前用户 $CURRENT_USER……"
RESULT=$(pm clear --user "$CURRENT_USER" "$GMS" 2>&1)
STATUS=$?
if [ "$STATUS" = 0 ] && [ "$RESULT" = Success ]; then
  echo "清理完成。"
else
  echo "清理失败：${RESULT:-系统未返回有效结果}"
  exit 1
fi
