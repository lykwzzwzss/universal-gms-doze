#!/system/bin/sh

# 仅在安装时调用。旧覆盖必须与当前系统视图一致，才允许跨版本保留。
gms_install_xml() (
  SOURCE_XML=$1
  TARGET_XML=$2
  OLD_XML=$3
  PATCH_XML="$XML_WORK/patched.xml"
  PATCH_STATUS=3
  if grep -qF "$GMS" "$SOURCE_XML"; then
    if awk -v mode=changed -f "$MODPATH/xml-patch.awk" "$SOURCE_XML" > "$PATCH_XML"; then
      PATCH_STATUS=0
    else
      PATCH_STATUS=$?
    fi
  fi
  case "$PATCH_STATUS" in
    0) INSTALL_XML=$PATCH_XML ;;
    3)
      # 升级时系统文件可能已经是旧覆盖，甚至不再包含 GMS 字符串。
      [ -f "$OLD_XML" ] && cmp -s "$SOURCE_XML" "$OLD_XML" || exit 0
      # 旧文件也要通过结构校验，不能在升级时沿用损坏配置。
      if ! awk -v mode=check -f "$MODPATH/xml-patch.awk" "$OLD_XML" >/dev/null; then
        ui_print "  跳过无法安全处理的旧覆盖：$SOURCE_XML"
        exit 0
      fi
      INSTALL_XML=$OLD_XML ;;
    *) ui_print "  跳过无法安全处理的 XML：$SOURCE_XML"; exit 0 ;;
  esac
  mkdir -p "${TARGET_XML%/*}" || exit 1
  if [ ! -f "$TARGET_XML" ] || ! cmp -s "$INSTALL_XML" "$TARGET_XML"; then
    cp -f "$INSTALL_XML" "$TARGET_XML" || exit 1
  fi
  ui_print "  已生成或保留覆盖：$SOURCE_XML"
)
