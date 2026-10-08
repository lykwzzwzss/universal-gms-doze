#!/system/bin/sh

STATE_DIR=${GMS_STATE_DIR:-/data/adb/universal-gms-doze}
. "$STATE_DIR/common.sh"
# 重新安装后不要让旧任务添加豁免。
if [ -f /data/adb/modules/universal-gms-doze/module.prop ] && \
   [ ! -f /data/adb/modules/universal-gms-doze/remove ]; then
  rm -f /data/adb/service.d/universal-gms-doze-restore.sh
  exit 0
fi
gms_wait_boot || exit 1
# 服务异常时留到下次启动重试，不在本次开机反复执行 dumpsys。
gms_read_lists || exit 1
gms_load_state || exit 1
if [ "$BASE_USER" = 1 ] && [ "$USER_REMOVED" = 1 ]; then
  gms_deviceidle whitelist "+$GMS" >/dev/null 2>&1
fi
if [ "$BASE_SYS" = 1 ] && [ "$SYS_REMOVED" = 1 ]; then
  gms_deviceidle sys-whitelist "+$GMS" >/dev/null 2>&1
fi
gms_read_lists || exit 1
if [ "$BASE_USER" = 1 ] && [ "$USER_REMOVED" = 1 ] && [ "$GMS_USER" != 1 ]; then exit 1; fi
if [ "$BASE_SYS" = 1 ] && [ "$SYS_REMOVED" = 1 ] && [ "$GMS_SYS" != 1 ]; then exit 1; fi
# 失败则保留任务，下次启动重试；成功只删除本模块的明确文件。
rm -f "$STATE_FILE" "$STATE_DIR/whitelist.state.legacy" "$STATE_DIR/service.log" "$STATE_DIR/common.sh"
rmdir "$STATE_DIR" 2>/dev/null
rm -f /data/adb/service.d/universal-gms-doze-restore.sh
exit 0
