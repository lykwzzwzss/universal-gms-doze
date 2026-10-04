#!/system/bin/sh

GMS=com.google.android.gms
STATE_DIR=${GMS_STATE_DIR:-/data/adb/universal-gms-doze}
STATE_FILE="$STATE_DIR/whitelist.state"

gms_read_lists() {
  GMS_LISTS=$(dumpsys deviceidle whitelist 2>/dev/null) || return 1
  printf '%s\n' "$GMS_LISTS" | grep -qE '^(system-excidle|system|user),[^,]+,[0-9]+$' || return 1
  GMS_USER=$(printf '%s\n' "$GMS_LISTS" | awk -F, -v p="$GMS" '$1=="user" && $2==p {found=1} END {print found+0}')
  GMS_SYS=$(printf '%s\n' "$GMS_LISTS" | awk -F, -v p="$GMS" '$1=="system" && $2==p {found=1} END {print found+0}')
  GMS_EXCEPT=unknown
  GMS_EXCEPT_RESULT=$(dumpsys deviceidle except-idle-whitelist "=$GMS" 2>/dev/null)
  case "$GMS_EXCEPT_RESULT" in
    true|1) GMS_EXCEPT=1 ;;
    false|0) GMS_EXCEPT=0 ;;
    *)
      if printf '%s\n' "$GMS_LISTS" | grep -q '^system-excidle,'; then
        GMS_EXCEPT=$(printf '%s\n' "$GMS_LISTS" | awk -F, -v p="$GMS" '($1=="system-excidle" || $1=="system" || $1=="user") && $2==p {found=1} END {print found+0}')
      fi ;;
  esac
}

gms_read_removed() {
  GMS_DUMP=$(dumpsys deviceidle 2>/dev/null) || return 1
  printf '%s\n' "$GMS_DUMP" | grep -q 'Whitelist' || return 1
  GMS_REMOVED=$(printf '%s\n' "$GMS_DUMP" | awk -v p="$GMS" '
    /Removed from whitelist system apps:/ {section=1; next}
    section && /^  [^ ]/ {section=0}
    section {line=$0; gsub(/^[ \t]+|[ \t\r]+$/, "", line); if(line==p) found=1}
    END {print found+0}')
}
gms_state_get() {
  [ -f "$STATE_FILE" ] || return 1
  awk -F= -v key="$1" '$1==key && NF==2 {print $2; exit}' "$STATE_FILE"
}
gms_load_state() {
  [ "$(gms_state_get schema)" = 2 ] || return 1
  BASE_USER=$(gms_state_get user_whitelist)
  BASE_SYS=$(gms_state_get sys_whitelist)
  BASE_EXCEPT=$(gms_state_get except_idle_whitelist)
  BASE_REMOVED=$(gms_state_get removed_system_whitelist)
  USER_REMOVED=$(gms_state_get user_removed)
  SYS_REMOVED=$(gms_state_get sys_removed)
  LEGACY_USER_UNKNOWN=$(gms_state_get legacy_user_unknown)
  for BOOL in "$BASE_USER" "$BASE_SYS" "$BASE_REMOVED" "$USER_REMOVED" "$SYS_REMOVED" "$LEGACY_USER_UNKNOWN"; do
    case "$BOOL" in 0|1) ;; *) return 1 ;; esac
  done
  case "$BASE_EXCEPT" in 0|1|unknown) ;; *) return 1 ;; esac
}
gms_save_state() {
  (umask 077
    mkdir -p "$STATE_DIR" || exit 1
    chmod 700 "$STATE_DIR" || exit 1
    STATE_TMP="$STATE_FILE.tmp.$$"
    {
      printf 'schema=2\nuser_whitelist=%s\nsys_whitelist=%s\nexcept_idle_whitelist=%s\nremoved_system_whitelist=%s\nuser_removed=%s\nsys_removed=%s\nlegacy_user_unknown=%s\n' \
        "$BASE_USER" "$BASE_SYS" "$BASE_EXCEPT" "$BASE_REMOVED" "$USER_REMOVED" "$SYS_REMOVED" "$LEGACY_USER_UNKNOWN"
    } > "$STATE_TMP" || exit 1
    chmod 600 "$STATE_TMP" && mv -f "$STATE_TMP" "$STATE_FILE")
}
gms_snapshot() {
  gms_load_state && return 0
  [ "$(gms_state_get schema)" != 2 ] || return 1
  gms_read_lists && gms_read_removed || return 1
  BASE_USER=$GMS_USER
  BASE_SYS=$GMS_SYS
  BASE_EXCEPT=$GMS_EXCEPT
  BASE_REMOVED=$GMS_REMOVED
  USER_REMOVED=0
  SYS_REMOVED=0
  LEGACY_USER_UNKNOWN=0
  if [ -f "$STATE_FILE" ]; then
    [ "$(gms_state_get sys_whitelist)" = 1 ] || [ "$(gms_state_get sys_whitelist)" = 0 ] || return 1
    # 1.9.4 混淆用户和系统白名单，保留当前真实用户状态并标记无法重建。
    LEGACY_USER_UNKNOWN=1
    if [ "$(gms_state_get sys_whitelist)" = 1 ] && [ "$GMS_REMOVED" = 1 ]; then
      BASE_SYS=1
      BASE_REMOVED=0
      SYS_REMOVED=1
    fi
    cp -p "$STATE_FILE" "$STATE_DIR/whitelist.state.legacy" || return 1
  fi
  gms_save_state
}
gms_log() { printf '%s\n' "$*" >> "$STATE_DIR/service.log"; }
