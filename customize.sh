#!/data/adb/magisk/busybox sh
set -o standalone

set -x

#
# 通用 GMS Doze
# 修改 Google Play 服务的系统配置，使其可以使用 Android 电池优化。
#

ui_print "- 检查 Root 实现"
if [ "$BOOTMODE" ] && [ "$KSU" ]; then
  ui_print "- 从 KernelSU 应用安装"
  ui_print "   KernelSU 版本：$KSU_KERNEL_VER_CODE（内核）+ $KSU_VER_CODE（ksud）"
  if [ "$(which magisk)" ]; then
    ui_print "   不支持同时运行多个 Root 实现"
    abort "   安装已中止"
  fi
elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
  ui_print "- 从 Magisk 应用安装"
else
  ui_print "   不支持从 Recovery 安装"
  ui_print "   请从 Magisk 或 KernelSU 应用安装"
  abort "   安装已中止"
fi

[ "$API" -ge 23 ] || abort "- 不支持的 Android API 版本：$API"

# 从系统电池优化 XML 中移除 GMS。
# 不修改其他模块拥有的 XML 文件。
ui_print "- 修改系统 XML 文件"
{
  GMS0="com.google.android.gms"
  QUOTE="[\"']"
  STR1="allow-in-power-save package=$QUOTE$GMS0$QUOTE"
  STR2="allow-in-data-usage-save package=$QUOTE$GMS0$QUOTE"
  STR3="allow-in-power-save-except-idle package=$QUOTE$GMS0$QUOTE"
  NULL="/dev/null"
}

SYS_XML="$(
  find /system_ext/* /system/* /product/* /vendor/* /india/* /my_bigball/* \
    -type f -iname '*.xml' -print 2>"$NULL" |
  while IFS= read -r S; do
    if grep -qE "$STR1|$STR2|$STR3" "$ROOT$S" 2>"$NULL"; then
      echo "$S"
    fi
  done
)"

for S in $SYS_XML; do
  mkdir -p "$(dirname "$MODPATH$S")"
  cp -af "$ROOT$S" "$MODPATH$S"
  ui_print "  修改：$S"
  sed -i "/$STR1/d;/$STR2/d;/$STR3/d" "$MODPATH$S"
done

# 在需要时将 product/vendor 覆盖文件合并到 /system 下。
for P in product vendor; do
  if [ -d "$MODPATH/$P" ]; then
    ui_print "- 合并模块目录"
    mkdir -p "$MODPATH/system/$P"
    cp -af "$MODPATH/$P/." "$MODPATH/system/$P/" 2>"$NULL"
    rm -rf "$MODPATH/$P"
  fi
done

ADDON() {
  ui_print "- 安装状态检查工具"
  mkdir -p "$MODPATH/system/bin"
  mv -f "$MODPATH/gmsc" "$MODPATH/system/bin/gmsc"
}

FINALIZE() {
  ui_print "- 完成安装"
  find "$MODPATH"/* -maxdepth 0 \
    ! -name 'module.prop' \
    ! -name 'post-fs-data.sh' \
    ! -name 'service.sh' \
    ! -name 'action.sh' \
    ! -name 'system' \
    -exec rm -rf {} \;

  set_perm_recursive "$MODPATH" 0 0 0755 0755
  set_perm "$MODPATH/system/bin/gmsc" 0 2000 0755
}

ADDON && FINALIZE
