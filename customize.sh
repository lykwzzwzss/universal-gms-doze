#!/system/bin/sh

[ "$BOOTMODE" = true ] || abort "- 请在 Magisk、KernelSU 或 APatch 管理器中安装"
if [ "$APATCH" = true ]; then
  ui_print "- 从 APatch 安装"
elif [ "$KSU" = true ]; then
  ui_print "- 从 KernelSU 安装"
elif [ -n "$MAGISK_VER_CODE" ]; then
  ui_print "- 从 Magisk 安装"
else
  abort "- 无法识别 Root 实现"
fi
[ "${API:-0}" -ge 23 ] || abort "- 需要 Android 6.0 或更高版本"
. "$MODPATH/common.sh"
ui_print "- 保存修改生效前的白名单状态"
gms_snapshot || abort "- 无法可靠读取或保存白名单；安装已中止"

# 直接生成标准挂载目录，分区移动和兼容链接交给管理器。
[ ! -L "$MODPATH/system" ] || abort "- 模块 system 目录不能是符号链接"
mkdir -p "$MODPATH/system" || abort "- 无法创建模块目录"
XML_WORK="$TMPDIR/gmsdoze-xml"
mkdir -p "$XML_WORK" || abort "- 无法创建 XML 临时目录"
for PARTITION in system product vendor system_ext odm; do
  if [ "$PARTITION" = system ]; then
    SOURCE_BASE=/system
    TARGET_BASE="$MODPATH/system"
  else
    SOURCE_BASE="/$PARTITION"
    [ -d "$SOURCE_BASE/etc" ] || SOURCE_BASE="/system/$PARTITION"
    TARGET_BASE="$MODPATH/system/$PARTITION"
    if [ -L "$TARGET_BASE" ]; then
      rm -f "$TARGET_BASE" || abort "- 无法修复模块分区链接"
    fi
  fi
  for CONFIG_DIR in "$SOURCE_BASE/etc/sysconfig" "$SOURCE_BASE/etc/permissions"; do
    [ -d "$CONFIG_DIR" ] || continue
    find -L "$CONFIG_DIR" -type f -name '*.xml' 2>/dev/null |
    while IFS= read -r SOURCE_XML; do
      grep -qF "$GMS" "$SOURCE_XML" || continue
      if ! awk -f "$MODPATH/xml-patch.awk" "$SOURCE_XML" > "$XML_WORK/patched.xml"; then
        ui_print "  跳过无法安全处理的 XML：$SOURCE_XML"
        continue
      fi
      cmp -s "$SOURCE_XML" "$XML_WORK/patched.xml" && continue
      TARGET_XML="$TARGET_BASE${SOURCE_XML#"$SOURCE_BASE"}"
      mkdir -p "${TARGET_XML%/*}" || exit 1
      cp -f "$XML_WORK/patched.xml" "$TARGET_XML" || exit 1
      ui_print "  已修改：$SOURCE_XML"
    done || abort "- 写入 XML 覆盖失败"
  done
done
mkdir -p "$MODPATH/system/bin" || abort "- 无法创建工具目录"
mv -f "$MODPATH/gmsc" "$MODPATH/system/bin/gmsc" || abort "- 无法安装检测工具"
# 不按保留名单删除文件，避免丢失卸载脚本和分区目录。
set_perm_recursive "$MODPATH" 0 0 0755 0644
for SCRIPT in service.sh post-fs-data.sh uninstall.sh action.sh restore.sh; do
  set_perm "$MODPATH/$SCRIPT" 0 0 0755
done
set_perm "$MODPATH/system/bin/gmsc" 0 2000 0755
ui_print "- 安装完成，请重启后运行 gmsc 检查"
ui_print "- 默认保留 GMS 数据；模块操作按钮提供音量键确认清理"
