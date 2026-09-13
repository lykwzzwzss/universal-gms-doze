#!/system/bin/sh

# 这是可选的 GMS 数据清理操作，不会在安装或升级时自动执行。
# 可在 Magisk/KernelSU 的模块操作按钮中执行，也可以手动运行本脚本。

GMS="com.google.android.gms"
NULL="/dev/null"

echo "准备清除 Google Play 服务数据。此操作可能导致账号重新登录、推送令牌重建。"

for USER_ID in $(ls /data/user 2>"$NULL"); do
  pm clear --user "$USER_ID" "$GMS" 2>"$NULL"
  if [ "$?" = "0" ]; then
    echo "已清除用户 $USER_ID 的 Google Play 服务数据。"
  else
    echo "清除用户 $USER_ID 的数据失败或不受支持。"
  fi
done

exit 0
