#!/system/bin/sh

GMS="com.google.android.gms"
STATE_FILE="/data/adb/universal-gms-doze/whitelist.state"
NULL="/dev/null"

# 只恢复模块安装前就存在的白名单项目。
if [ -f "$STATE_FILE" ]; then
  . "$STATE_FILE"

  if [ "$user_whitelist" = "1" ]; then
    dumpsys deviceidle whitelist +$GMS &>"$NULL"
  fi
  if [ "$sys_whitelist" = "1" ]; then
    dumpsys deviceidle sys-whitelist +$GMS &>"$NULL"
  fi

  rm -f "$STATE_FILE"
  rmdir /data/adb/universal-gms-doze 2>"$NULL"
fi

exit 0
