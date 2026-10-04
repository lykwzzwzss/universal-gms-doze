#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"
# 有界等待，不依赖 /sdcard，不强制改变休眠状态。
TRIES=0
until [ "$(getprop sys.boot_completed)" = 1 ]; do
  TRIES=$((TRIES + 1))
  [ "$TRIES" -lt 120 ] || exit 1
  sleep 5
done
gms_load_state || exit 1
: > "$STATE_DIR/service.log"
if ! gms_read_lists; then
  gms_log "无法查询白名单，未修改；请重启后检查。"
  exit 1
fi
if [ "$GMS_USER" = 1 ]; then
  USER_REMOVED=1
  gms_save_state || exit 1
  dumpsys deviceidle whitelist "-$GMS" >> "$STATE_DIR/service.log" 2>&1
fi
if [ "$GMS_SYS" = 1 ]; then
  SYS_REMOVED=1
  gms_save_state || exit 1
  dumpsys deviceidle sys-whitelist "-$GMS" >> "$STATE_DIR/service.log" 2>&1
fi
if ! gms_read_lists; then
  gms_log "修改后查询失败，优化状态未知。"
  exit 1
fi
if [ "$GMS_USER" = 1 ] || [ "$GMS_SYS" = 1 ]; then
  gms_log "完整 Doze 豁免仍存在，当前系统可能不支持移除。"
  exit 1
fi
gms_log "完整 Doze 豁免已移除；其他省电豁免状态：$GMS_EXCEPT（0=无，1=有）。"
if [ "$GMS_EXCEPT" = 1 ]; then
  gms_log "其他省电豁免仍存在，请检查 XML 挂载、元模块或同路径模块冲突。"
fi
