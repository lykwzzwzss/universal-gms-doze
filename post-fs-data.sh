#!/data/adb/magisk/busybox sh
set -o standalone

#
# Universal GMS Doze by the
# open-source loving GL-DP and all contributors;
# Patches Google Play services app and certain processes/services to be able to use battery optimization
#

# Search and patch any conflicting modules (if present)

{
GMS0="com.google.android.gms"
QUOTE="[\"']"
STR1="allow-unthrottled-location package=$QUOTE$GMS0$QUOTE"
STR2="allow-ignore-location-settings package=$QUOTE$GMS0$QUOTE"
STR3="allow-in-power-save package=$QUOTE$GMS0$QUOTE"
STR4="allow-in-data-usage-save package=$QUOTE$GMS0$QUOTE"
STR5="allow-in-power-save-except-idle package=$QUOTE$GMS0$QUOTE"
NULL="/dev/null"
}

{
find /data/adb/* -type f -iname "*.xml" -print |
while IFS= read -r XML; do
for X in $XML; do
if grep -qE "$STR1|$STR2|$STR3|$STR4|$STR5" $X 2> $NULL; then
sed -i "/$STR1/d;/$STR2/d;/$STR3/d;/$STR4/d;/$STR5/d" $X
fi
done
done
}
