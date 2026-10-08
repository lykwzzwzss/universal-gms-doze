#!/usr/bin/env bash
set -eu
PATH=/usr/bin:/bin:$PATH
cd "$(dirname "$0")/.."
TEST_DIR=$(mktemp -d /tmp/ugms196.XXXXXXXX)
trap 'case "$TEST_DIR" in /tmp/ugms196.*) rm -rf -- "$TEST_DIR" ;; esac' EXIT
COUNT=0
pass() { COUNT=$((COUNT + 1)); printf 'PASS %s\n' "$1"; }
check() { [ "$1" = "$2" ] || { printf 'FAIL %s: actual=%s expected=%s\n' "$3" "$1" "$2"; exit 1; }; pass "$3"; }
for file in customize.sh common.sh service.sh uninstall.sh restore.sh action.sh xml-install.sh gmsc META-INF/com/google/android/update-binary; do bash -n "$file"; done
pass "shell syntax"
xml() { printf '%s\n' "$1" | awk -f xml-patch.awk; }
check "$(xml '<config><allow-in-power-save package="com.google.android.gms"/><feature name="keep"/></config>')" '<config><feature name="keep"/></config>' "single-line XML"
check "$(xml '<config><allow-in-power-save other="x" package = "com.google.android.gms"/><allow-in-power-save package="com.google.android.gms.other"/></config>')" '<config><allow-in-power-save package="com.google.android.gms.other"/></config>' "attributes and exact package"
check "$(xml "<config><allow-in-power-save-except-idle package='com.google.android.gms'></allow-in-power-save-except-idle></config>")" '<config></config>' "single quotes and paired empty node"
check "$(xml '<config><!-- <allow-in-power-save package="com.google.android.gms"/> --><keep><![CDATA[<allow-in-power-save package="com.google.android.gms"/>]]></keep></config>')" '<config><!-- <allow-in-power-save package="com.google.android.gms"/> --><keep><![CDATA[<allow-in-power-save package="com.google.android.gms"/>]]></keep></config>' "comments and CDATA"
check "$(xml '<config><allow-in-power-save
  package="com.google.android.gms" /></config>')" '<config></config>' "multiline attributes"
for input in '<config><broken></config>' '<config><allow-in-power-save package="com.google.android.gms">not empty</allow-in-power-save></config>' '<!DOCTYPE config><config/>' '<config><allow-in-power-save package="com.google.android.gms"/>' '<config/><second/>'; do
  if xml "$input" > "$TEST_DIR/rejected.xml"; then echo "FAIL invalid XML accepted"; exit 1; fi
  [ ! -s "$TEST_DIR/rejected.xml" ] || { echo "FAIL partial XML output"; exit 1; }
done
pass "unsafe XML rejected without partial output"
GMS_STATE_DIR="$TEST_DIR/state"
# 模拟超时器，Android 调用只到测试函数，绝不访问真实设备。
timeout() {
  [ "$1/$2" = '-k/2' ] || return 99
  shift 2
  printf '%s\n' "$*" >> "$TEST_DIR/timeouts"
  shift
  "$@"
}
. ./common.sh
printf 'system,android,1000\nsystem,com.google.android.gms,10112\nsystem-excidle,com.google.android.gms,10112\n' > "$TEST_DIR/lists"
printf '  Whitelist system apps:\n    com.google.android.gms\n  Whitelist user apps:\n' > "$TEST_DIR/dump"
QUERY=true
FAIL_QUERY=0
dumpsys() {
  printf '%s\n' "$*" >> "$TEST_DIR/dumpsys-calls"
  [ "$FAIL_QUERY" = 0 ] || return 1
  if [ "${FAIL_REMOVE:-0}" = 1 ] && [ "${3:-}" = -com.google.android.gms ]; then return 1; fi
  case "${2:-}" in
    whitelist)
      case "${3:-}" in
        -com.google.android.gms) sed -i '/^user,com.google.android.gms,/d' "$TEST_DIR/lists" ;;
        +com.google.android.gms) printf 'user,com.google.android.gms,10112\n' >> "$TEST_DIR/lists" ;;
        *) cat "$TEST_DIR/lists" ;;
      esac ;;
    sys-whitelist)
      case "${3:-}" in
        -com.google.android.gms) sed -i '/^system,com.google.android.gms,/d' "$TEST_DIR/lists" ;;
        +com.google.android.gms) printf 'system,com.google.android.gms,10112\n' >> "$TEST_DIR/lists" ;;
        *) return 1 ;;
      esac ;;
    except-idle-whitelist) printf '%s\n' "$QUERY"; return "${EXCEPT_FAIL:-0}" ;;
    get) printf '%s\n' "${STATE_RESULT:-INACTIVE}"; return "${STATE_FAIL:-0}" ;;
    *) cat "$TEST_DIR/dump" ;;
  esac
}
gms_snapshot
check "$BASE_USER" 0 "system entry never becomes user baseline"
check "$BASE_SYS" 1 "snapshot before XML changes"
printf 'system,android,1000\nsystem-excidle,com.google.android.gms,10112\n' > "$TEST_DIR/lists"
gms_snapshot
check "$BASE_SYS" 1 "upgrade preserves original snapshot"
gms_read_lists
check "$GMS_USER/$GMS_SYS/$GMS_EXCEPT" '0/0/1' "partial optimization separated"
QUERY='No arguments given'
gms_read_lists
check "$GMS_EXCEPT" 1 "except-idle fallback"
FAIL_QUERY=1
if gms_read_lists; then echo "FAIL query failure reported as success"; exit 1; fi
pass "query failures stay unknown"
FAIL_QUERY=0
QUERY=true
printf 'user_whitelist=1\nsys_whitelist=1\n' > "$STATE_FILE"
printf '  Whitelist system apps:\n  Removed from whitelist system apps:\n    com.google.android.gms\n  Whitelist user apps:\n' > "$TEST_DIR/dump"
gms_snapshot
check "$BASE_USER/$BASE_SYS/$SYS_REMOVED/$LEGACY_USER_UNKNOWN" '0/1/1/1' "legacy migration restores system only"
[ -f "$STATE_DIR/whitelist.state.legacy" ]
printf 'schema=2\nuser_whitelist=oops\n' > "$STATE_FILE"
if gms_snapshot; then echo "FAIL corrupt snapshot silently replaced"; exit 1; fi
pass "corrupt state not overwritten"
# Restore only recorded removals; failed restore keeps the recovery files.
BASE_USER=0
BASE_SYS=1
BASE_EXCEPT=1
BASE_REMOVED=0
USER_REMOVED=0
SYS_REMOVED=1
LEGACY_USER_UNKNOWN=1
gms_save_state
cp common.sh "$STATE_DIR/common.sh"
getprop() { printf '1\n'; }
rm() { printf '%s\n' "$*" >> "$TEST_DIR/restore-cleanup"; }
( set +e; . ./restore.sh )
gms_read_lists
check "$GMS_USER/$GMS_SYS" '0/1' "restore system without adding user exemption"
[ -f "$TEST_DIR/restore-cleanup" ]
command rm -f "$TEST_DIR/restore-cleanup"
printf 'system,android,1000\n' > "$TEST_DIR/lists"
RESTORE_FAIL=1
original_dumpsys=$(declare -f dumpsys)
eval "${original_dumpsys/dumpsys ()/mock_dumpsys ()}"
dumpsys() {
  case "${3:-}" in +com.google.android.gms) return 1 ;; esac
  mock_dumpsys "$@"
}
if ( set +e; . ./restore.sh ); then echo "FAIL restore failure discarded backup"; exit 1; fi
[ ! -f "$TEST_DIR/restore-cleanup" ]
pass "failed restore retains state and recovery task"
eval "$original_dumpsys"
unset -f rm
# Execute the real service script in a child shell against fake Android services.
BASE_USER=1
BASE_SYS=1
USER_REMOVED=0
SYS_REMOVED=0
gms_save_state
printf 'system,android,1000\nsystem,com.google.android.gms,10112\nuser,com.google.android.gms,10112\n' > "$TEST_DIR/lists"
export TEST_DIR GMS_STATE_DIR QUERY FAIL_QUERY
export -f dumpsys getprop timeout
bash ./service.sh
gms_load_state
gms_read_lists
check "$GMS_USER/$GMS_SYS/$USER_REMOVED/$SYS_REMOVED" '0/0/1/1' "service removes both lists and records restoration"
before=$(wc -l < "$TEST_DIR/dumpsys-calls")
bash ./service.sh
after=$(wc -l < "$TEST_DIR/dumpsys-calls")
check "$((after - before))" 2 "already-optimized boot does not repeat system queries"
printf 'system,android,1000\nsystem,com.google.android.gms,10112\n' > "$TEST_DIR/lists"
FAIL_REMOVE=1
export FAIL_REMOVE
if bash ./service.sh; then echo 'FAIL removal failure reported success'; exit 1; fi
pass "failed whitelist removal is detected by verification"
FAIL_REMOVE=0
printf 'system,android,1000\n' > "$TEST_DIR/lists"
FAIL_QUERY=1
if bash ./service.sh; then echo "FAIL service silently accepted failed queries"; exit 1; fi
pass "service fails safely on query errors"
FAIL_QUERY=0
id() { printf '0\n'; }
am() {
  printf 'query\n' >> "$TEST_DIR/user-queries"
  case "${MOCK_USER_MODE:-normal}" in
    fail) printf '10\n'; return 124 ;;
    switch)
      if [ "$(wc -l < "$TEST_DIR/user-queries")" -gt 1 ]; then printf '11\n'; else printf '10\n'; fi ;;
    *) printf '10\n' ;;
  esac
}
getevent() {
  case "$MOCK_KEY" in
    up) printf 'EV_KEY KEY_VOLUMEUP DOWN\n' ;;
    down) printf 'EV_KEY KEY_VOLUMEDOWN DOWN\n' ;;
    up-release) printf 'EV_KEY KEY_VOLUMEUP UP\n' ;;
    *) return 124 ;;
  esac
}
pm() { printf '%s\n' "$*" >> "$TEST_DIR/pm-calls"; printf 'Success\n'; return "${PM_RESULT_CODE:-0}"; }
for MOCK_KEY in down timeout up-release; do
  export MOCK_KEY
  export -f id am pm timeout getevent
  bash ./action.sh > "$TEST_DIR/action-output"
  [ ! -f "$TEST_DIR/pm-calls" ] || { echo "FAIL cancelled action cleared data"; exit 1; }
done
pass "down timeout and key release cancel"
MOCK_KEY=up
bash ./action.sh > "$TEST_DIR/action-output"
check "$(cat "$TEST_DIR/pm-calls")" 'clear --user 10 com.google.android.gms' "confirm clears only current user (mock)"
command rm -f "$TEST_DIR/pm-calls" "$TEST_DIR/user-queries"
MOCK_USER_MODE=switch
export MOCK_USER_MODE
bash ./action.sh > "$TEST_DIR/action-output"
[ ! -f "$TEST_DIR/pm-calls" ]
pass "user switch after confirmation cancels clearing"
MOCK_USER_MODE=fail
if bash ./action.sh > "$TEST_DIR/action-output"; then echo 'FAIL user query timeout accepted'; exit 1; fi
[ ! -f "$TEST_DIR/pm-calls" ]
pass "user query timeout cannot clear data"
MOCK_USER_MODE=normal
PM_RESULT_CODE=124
export PM_RESULT_CODE
if bash ./action.sh > "$TEST_DIR/action-output"; then echo 'FAIL clear timeout reported success'; exit 1; fi
grep -q '结果未知' "$TEST_DIR/action-output"
pass "clear timeout reports unknown even with success text"
PM_RESULT_CODE=143
if bash ./action.sh > "$TEST_DIR/action-output"; then echo 'FAIL BusyBox timeout reported success'; exit 1; fi
grep -q '结果未知' "$TEST_DIR/action-output"
pass "BusyBox TERM timeout reports unknown"
PM_RESULT_CODE=1
if bash ./action.sh > "$TEST_DIR/action-output"; then echo 'FAIL clear failure reported success'; exit 1; fi
grep -q '清理失败' "$TEST_DIR/action-output"
pass "clear command failure is not success"
unset MOCK_USER_MODE PM_RESULT_CODE

# 超时、错误残片和损坏备份不能被解释为优化成功。
printf 'system,android,1000\nDUMP TIMEOUT\n' > "$TEST_DIR/lists"
if gms_read_lists; then echo 'FAIL partial dump accepted'; exit 1; fi
check "$GMS_USER/$GMS_SYS/$GMS_EXCEPT" unknown/unknown/unknown "partial dump stays unknown"
printf 'system,android,1000\n' > "$TEST_DIR/lists"
EXCEPT_FAIL=1
QUERY=false
gms_read_lists
check "$GMS_EXCEPT" unknown "failed except-idle query does not trust boolean output"
EXCEPT_FAIL=0
QUERY=true
gms_save_state
printf 'user_whitelist=0\n' >> "$STATE_FILE"
if gms_snapshot; then echo 'FAIL duplicate backup accepted'; exit 1; fi
pass "duplicate state rejected"
BASE_USER=1
gms_save_state
sed -i 's/schema=2/schema=99/' "$STATE_FILE"
if gms_snapshot; then echo 'FAIL future schema overwritten'; exit 1; fi
check "$(gms_state_get schema)" 99 "unknown schema retained"
gms_save_state

# 系统服务故障不在本次开机高频重试。
cp common.sh "$STATE_DIR/common.sh"
before=$(wc -l < "$TEST_DIR/dumpsys-calls")
FAIL_QUERY=1
if ( set +e; . ./restore.sh ); then echo 'FAIL restore query error accepted'; exit 1; fi
after=$(wc -l < "$TEST_DIR/dumpsys-calls")
check "$((after - before))" 1 "restore stops after first failed query"
FAIL_QUERY=0
(
  getprop() { printf '0\n'; }
  sleep() { printf 'wait\n' >> "$TEST_DIR/boot-waits"; }
  if gms_wait_boot; then exit 1; fi
)
check "$(wc -l < "$TEST_DIR/boot-waits" | tr -d ' ')" 119 "boot wait has finite retry budget"
STATE_RESULT='Error: unavailable'
export STATE_RESULT
bash ./gmsc > "$TEST_DIR/status-output"
grep -q '当前深度 Doze：未知；轻度 Doze：未知' "$TEST_DIR/status-output"
pass "invalid Doze state output stays unknown"
grep -q 'except-idle 部分豁免' "$TEST_DIR/status-output"
grep -q '不涵盖 MIUI 策略' "$TEST_DIR/status-output"
pass "status labels do not claim to inspect every OEM exemption"
STATE_RESULT=ACTIVE
STATE_FAIL=1
export STATE_FAIL
bash ./gmsc > "$TEST_DIR/status-output"
grep -q '当前深度 Doze：未知；轻度 Doze：未知' "$TEST_DIR/status-output"
pass "failed Doze state query stays unknown"
unset STATE_RESULT STATE_FAIL

# 检查包装器确实设置 15 秒限时和 2 秒强制退出兜底。
grep -q '^15 dumpsys deviceidle whitelist$' "$TEST_DIR/timeouts"
pass "deviceidle calls use bounded timeout"
(
  unset -f timeout
  gms_timeout 1 sh -c 'sleep 8' > "$TEST_DIR/real-timeout" 2>&1 && exit 1
  result=$?
  [ "$result" = 124 ] || [ "$result" = 137 ]
)
pass "real timeout terminates a stalled command"
(
  unset -f timeout
  gms_timeout 1 sh -c 'trap "" TERM; exec sleep 8' > "$TEST_DIR/kill-timeout" 2>&1 && exit 1
  result=$?
  [ "$result" = 137 ]
)
pass "timeout force-kills commands that ignore termination"

# 模拟升级时已挂载旧覆盖；不得因 GMS 字符串已移除而丢失覆盖。
. ./xml-install.sh
MODPATH=$PWD
XML_WORK="$TEST_DIR/xml-work"
mkdir -p "$XML_WORK" "$TEST_DIR/xml-source" "$TEST_DIR/xml-old"
ui_print() { printf '%s\n' "$*" >> "$TEST_DIR/install-output"; }
printf '<config><feature name="keep"/></config>\n' > "$TEST_DIR/xml-source/google.xml"
cp "$TEST_DIR/xml-source/google.xml" "$TEST_DIR/xml-old/google.xml"
gms_install_xml "$TEST_DIR/xml-source/google.xml" "$TEST_DIR/xml-new/google.xml" "$TEST_DIR/xml-old/google.xml"
cmp -s "$TEST_DIR/xml-new/google.xml" "$TEST_DIR/xml-source/google.xml"
pass "upgrade preserves an already-patched overlay without GMS text"
printf '<config><feature name="new-ota"/></config>\n' > "$TEST_DIR/xml-source/new.xml"
gms_install_xml "$TEST_DIR/xml-source/new.xml" "$TEST_DIR/xml-new/new.xml" "$TEST_DIR/xml-old/google.xml"
[ ! -f "$TEST_DIR/xml-new/new.xml" ]
pass "changed system file does not reuse stale overlay"
printf '<config><service package="com.google.android.gms"/></config>' > "$TEST_DIR/xml-source/unrelated.xml"
gms_install_xml "$TEST_DIR/xml-source/unrelated.xml" "$TEST_DIR/xml-new/unrelated.xml" "$TEST_DIR/xml-old/missing.xml"
[ ! -f "$TEST_DIR/xml-new/unrelated.xml" ]
pass "unrelated GMS XML without final newline creates no overlay"
printf '<config><allow-in-power-save package="com.google.android.gms"/><feature name="keep"/></config>\n' > "$TEST_DIR/xml-source/fresh.xml"
gms_install_xml "$TEST_DIR/xml-source/fresh.xml" "$TEST_DIR/xml-new/fresh.xml" "$TEST_DIR/xml-old/missing.xml"
check "$(cat "$TEST_DIR/xml-new/fresh.xml")" '<config><feature name="keep"/></config>' "fresh XML install preserves other nodes"
printf '<config><broken></config>\n' > "$TEST_DIR/xml-source/broken.xml"
cp "$TEST_DIR/xml-source/broken.xml" "$TEST_DIR/xml-old/broken.xml"
gms_install_xml "$TEST_DIR/xml-source/broken.xml" "$TEST_DIR/xml-new/broken.xml" "$TEST_DIR/xml-old/broken.xml"
[ ! -f "$TEST_DIR/xml-new/broken.xml" ]
pass "malformed old overlay is not carried forward"

# 在隔离目录执行安装收尾，确认只有模块内部工具，卸载脚本仍在。
(
  MODPATH="$TEST_DIR/module"
  TMPDIR="$TEST_DIR/installer-temp"
  mkdir -p "$MODPATH/system/bin" "$TMPDIR"
  cp common.sh xml-install.sh xml-patch.awk service.sh uninstall.sh action.sh restore.sh gmsc "$MODPATH/"
  printf 'old helper\n' > "$MODPATH/system/bin/gmsc"
  BOOTMODE=true KSU=true APATCH=false API=33 MAGISK_VER_CODE=''
  abort() { echo "FAIL install: $*"; exit 1; }
  set_perm_recursive() { :; }
  set_perm() { chmod "$4" "$1"; }
  . ./customize.sh
  [ -x "$MODPATH/gmsc" ] && [ -x "$MODPATH/uninstall.sh" ]
  [ ! -e "$MODPATH/system/bin/gmsc" ] && [ ! -d "$MODPATH/system/bin" ]
)
pass "installer retains internal helper and removes only its old bin entry"
# 将恢复任务目标重定向到测试目录，不能写宿主 /data/adb。
(
  mkdir() {
    if [ "$1/${2:-}" = '-p//data/adb/service.d' ]; then
      command mkdir -p "$TEST_DIR/service.d"
    else command mkdir "$@"; fi
  }
  mv() {
    if [ "${!#}" = /data/adb/service.d/universal-gms-doze-restore.sh ]; then
      command mv -f "$2" "$TEST_DIR/service.d/universal-gms-doze-restore.sh"
    else command mv "$@"; fi
  }
  export -f mkdir mv
  bash ./uninstall.sh
  cmp -s common.sh "$STATE_DIR/common.sh"
  cmp -s restore.sh "$TEST_DIR/service.d/universal-gms-doze-restore.sh"
  [ -x "$TEST_DIR/service.d/universal-gms-doze-restore.sh" ]
)
pass "uninstall atomically schedules complete restoration files (mock path)"
(
  mkdir() { :; }
  cp() {
    case "${2:-}" in */restore.sh) return 1 ;; esac
    command cp "$@"
  }
  # 失败分支不可提交任务；任何 mv 到真实恢复路径都视为测试失败。
  mv() {
    case "${!#}" in /data/adb/service.d/*) return 99 ;; esac
    command mv "$@"
  }
  export -f mkdir cp mv
  if bash ./uninstall.sh; then exit 1; fi
)
cmp -s restore.sh "$TEST_DIR/service.d/universal-gms-doze-restore.sh"
pass "failed recovery staging preserves previous task"
[ ! -f post-fs-data.sh ]
pass "no unnecessary blocking-stage boot script"
printf 'All %s checks passed.\n' "$COUNT"
