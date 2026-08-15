#!/data/adb/magisk/busybox sh
set -o standalone

#
# Universal GMS Doze by the
# open-source loving GL-DP and all contributors;
# Patches Google Play services app and certain processes/services to be able to use battery optimization
#

(   
# Wait until boot completed
until [ $(resetprop sys.boot_completed) -eq 1 ] &&
[ -d /sdcard ]; do
sleep 100
done

# GMS components
GMS="com.google.android.gms"
GC1="auth.managed.admin.DeviceAdminReceiver"
GC2="mdm.receivers.MdmDeviceAdminReceiver"
NLL="/dev/null"

# Disable collective device administrators
for U in $(ls /data/user); do
for C in $GC1 $GC2 $GC3; do
pm disable --user $U "$GMS/$GMS.$C" &> $NLL
done
done

# Remove GMS from the power-save whitelists.
# Android 14+ splits this into a user whitelist and a system whitelist;
# the plain "whitelist" command only affects the user whitelist, so GMS
# (a system app) also needs to be removed with "sys-whitelist".
dumpsys deviceidle whitelist -com.google.android.gms &> $NLL
dumpsys deviceidle sys-whitelist -com.google.android.gms &> $NLL

exit 0
)
