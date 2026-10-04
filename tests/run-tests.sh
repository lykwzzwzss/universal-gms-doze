#!/usr/bin/env bash
set -eu
PATH=/usr/bin:/bin:$PATH
cd "$(dirname "$0")/.."
TEST_DIR=$(mktemp -d /tmp/ugms195.XXXXXXXX)
trap 'case "$TEST_DIR" in /tmp/ugms195.*) rm -rf -- "$TEST_DIR" ;; esac' EXIT
COUNT=0
pass() { COUNT=$((COUNT + 1)); printf 'PASS %s\n' "$1"; }
check() { [ "$1" = "$2" ] || { printf 'FAIL %s: actual=%s expected=%s\n' "$3" "$1" "$2"; exit 1; }; pass "$3"; }
for file in customize.sh common.sh service.sh uninstall.sh restore.sh action.sh post-fs-data.sh gmsc META-INF/com/google/android/update-binary; do bash -n "$file"; done
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
. ./common.sh
printf 'system,android,1000\nsystem,com.google.android.gms,10112\nsystem-excidle,com.google.android.gms,10112\n' > "$TEST_DIR/lists"
printf '  Whitelist system apps:\n    com.google.android.gms\n  Whitelist user apps:\n' > "$TEST_DIR/dump"
QUERY=true
FAIL_QUERY=0
dumpsys() {
  [ "$FAIL_QUERY" = 0 ] || return 1
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
    except-idle-whitelist) printf '%s\n' "$QUERY" ;;
    get) printf 'INACTIVE\n' ;;
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
export -f dumpsys getprop
bash ./service.sh
gms_load_state
gms_read_lists
check "$GMS_USER/$GMS_SYS/$USER_REMOVED/$SYS_REMOVED" '0/0/1/1' "service removes both lists and records restoration"
FAIL_QUERY=1
if bash ./service.sh; then echo "FAIL service silently accepted failed queries"; exit 1; fi
pass "service fails safely on query errors"
FAIL_QUERY=0
id() { printf '0\n'; }
am() { printf '10\n'; }
timeout() {
  case "$MOCK_KEY" in
    up) printf 'EV_KEY KEY_VOLUMEUP DOWN\n' ;;
    down) printf 'EV_KEY KEY_VOLUMEDOWN DOWN\n' ;;
    up-release) printf 'EV_KEY KEY_VOLUMEUP UP\n' ;;
    *) return 124 ;;
  esac
}
pm() { printf '%s\n' "$*" >> "$TEST_DIR/pm-calls"; printf 'Success\n'; }
for MOCK_KEY in down timeout up-release; do
  ( . ./action.sh ) > "$TEST_DIR/action-output"
  [ ! -f "$TEST_DIR/pm-calls" ] || { echo "FAIL cancelled action cleared data"; exit 1; }
done
pass "down timeout and key release cancel"
MOCK_KEY=up
( . ./action.sh ) > "$TEST_DIR/action-output"
check "$(cat "$TEST_DIR/pm-calls")" 'clear --user 10 com.google.android.gms' "confirm clears only current user (mock)"
printf 'All %s checks passed.\n' "$COUNT"
