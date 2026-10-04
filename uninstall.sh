#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"
gms_load_state || exit 1
# 卸载常发生在系统服务启动前，下一次启动完成后再恢复。
mkdir -p /data/adb/service.d || exit 1
cp -f "$MODDIR/common.sh" "$STATE_DIR/common.sh" || exit 1
cp -f "$MODDIR/restore.sh" /data/adb/service.d/universal-gms-doze-restore.sh || exit 1
chmod 600 "$STATE_DIR/common.sh"
chmod 755 /data/adb/service.d/universal-gms-doze-restore.sh
