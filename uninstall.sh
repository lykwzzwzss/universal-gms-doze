#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"
gms_load_state || exit 1
# 卸载常发生在系统服务启动前，下一次启动完成后再恢复。
mkdir -p /data/adb/service.d || exit 1
# 先在私有目录写完整文件，再原子替换，避免半写入的恢复脚本被执行。
umask 077
COMMON_TMP="$STATE_DIR/common.sh.tmp.$$"
RESTORE_TMP="$STATE_DIR/restore.sh.tmp.$$"
trap 'rm -f "$COMMON_TMP" "$RESTORE_TMP"' 0
cp -f "$MODDIR/common.sh" "$COMMON_TMP" && chmod 600 "$COMMON_TMP" && \
  mv -f "$COMMON_TMP" "$STATE_DIR/common.sh" || exit 1
cp -f "$MODDIR/restore.sh" "$RESTORE_TMP" && chmod 755 "$RESTORE_TMP" && \
  mv -f "$RESTORE_TMP" /data/adb/service.d/universal-gms-doze-restore.sh || exit 1
