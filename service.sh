#!/data/adb/magisk/busybox sh
set -o standalone

GMS="com.google.android.gms"
STATE_DIR="/data/adb/universal-gms-doze"
STATE_FILE="$STATE_DIR/whitelist.state"
NULL="/dev/null"

contains_gms() {
  grep -qE "(^|[,[:space:]])$GMS([,[:space:]]|$)"
}

snapshot_state() {
  [ -f "$STATE_FILE" ] && return 0

  mkdir -p "$STATE_DIR"
  USER_WL=0
  SYS_WL=0

  if dumpsys deviceidle whitelist 2>"$NULL" | contains_gms; then
    USER_WL=1
  fi
  if dumpsys deviceidle sys-whitelist 2>"$NULL" | contains_gms; then
    SYS_WL=1
  fi

  umask 077
  {
    echo "user_whitelist=$USER_WL"
    echo "sys_whitelist=$SYS_WL"
  } > "$STATE_FILE"
  chmod 600 "$STATE_FILE"
}

# 等待 Android 完成启动并挂载外部存储。
until [ "$(resetprop sys.boot_completed)" = "1" ] && [ -d /sdcard ]; do
  sleep 10
done

# 只保存一次模块安装前的状态，然后从两个白名单中移除 GMS。
snapshot_state
dumpsys deviceidle whitelist -$GMS &>"$NULL"
dumpsys deviceidle sys-whitelist -$GMS &>"$NULL"

exit 0
