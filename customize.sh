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
. "$MODPATH/xml-install.sh"
ui_print "- 保存修改生效前的白名单状态"
gms_snapshot || abort "- 无法可靠读取或保存白名单；安装已中止"

# 直接生成标准挂载目录，分区移动和兼容链接交给管理器。
[ ! -L "$MODPATH/system" ] || abort "- 模块 system 目录不能是符号链接"
mkdir -p "$MODPATH/system" || abort "- 无法创建模块目录"
XML_WORK="$TMPDIR/gmsdoze-xml"
mkdir -p "$XML_WORK" || abort "- 无法创建 XML 临时目录"
OLD_MODULE=/data/adb/modules/universal-gms-doze
for PARTITION in system product vendor system_ext odm; do
  if [ "$PARTITION" = system ]; then
    SOURCE_BASE=/system
    TARGET_BASE="$MODPATH/system"
    OLD_BASE="$OLD_MODULE/system"
  else
    SOURCE_BASE="/$PARTITION"
    [ -d "$SOURCE_BASE/etc" ] || SOURCE_BASE="/system/$PARTITION"
    TARGET_BASE="$MODPATH/system/$PARTITION"
    OLD_BASE="$OLD_MODULE/system/$PARTITION"
    [ -d "$OLD_BASE/etc" ] || OLD_BASE="$OLD_MODULE/$PARTITION"
    if [ -L "$TARGET_BASE" ]; then
      rm -f "$TARGET_BASE" || abort "- 无法修复模块分区链接"
    fi
  fi
  for CONFIG_DIR in "$SOURCE_BASE/etc/sysconfig" "$SOURCE_BASE/etc/permissions"; do
    [ -d "$CONFIG_DIR" ] || continue
    find -L "$CONFIG_DIR" -type f -name '*.xml' 2>/dev/null |
    while IFS= read -r SOURCE_XML; do
      TARGET_XML="$TARGET_BASE${SOURCE_XML#"$SOURCE_BASE"}"
      OLD_XML="$OLD_BASE${SOURCE_XML#"$SOURCE_BASE"}"
      gms_install_xml "$SOURCE_XML" "$TARGET_XML" "$OLD_XML" || exit 1
    done || abort "- 写入 XML 覆盖失败"
  done
done
# 检测工具只保留在模块根目录；只清理本模块升级残留，不碰系统文件。
[ ! -L "$MODPATH/system/bin" ] || abort "- 模块工具目录不能是符号链接"
rm -f "$MODPATH/system/bin/gmsc" || abort "- 无法清理旧检测工具"
rmdir "$MODPATH/system/bin" 2>/dev/null || :
# 不按保留名单删除文件，避免丢失卸载脚本和分区目录。
set_perm_recursive "$MODPATH" 0 0 0755 0644
for SCRIPT in service.sh uninstall.sh action.sh restore.sh gmsc; do
  set_perm "$MODPATH/$SCRIPT" 0 0 0755
done
ui_print "- 安装完成，请重启后以 Root 身份运行："
ui_print "  sh /data/adb/modules/universal-gms-doze/gmsc"
ui_print "- 默认保留 GMS 数据；模块操作按钮提供音量键确认清理"
