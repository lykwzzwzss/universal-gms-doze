# Universal GMS Doze

> Community-maintained fork of [gloeyisk/universal-gms-doze](https://github.com/gloeyisk/universal-gms-doze),
> updated for Android 16 & Android 17. All credit for the original module goes to the upstream author.

## Overview
- Patches Google Play services app and certain processes/services to be able to use battery optimization
- Support API 23 or later (Android 6.0 - Android 17)
- Support Magisk, KernelSU, and APatch root implementations

## Download Links (Archive)
- Latest stable release: 1.9.3 (Android 16 & 17 support) on [GitHub Releases](https://github.com/lykwzzwzss/universal-gms-doze/releases)
- [GitHub Releases](https://kutt.it/3FfNzX)
- [Mediafire](https://app.mediafire.com/16j39nr5uxi4l)
- [MEGA](https://kutt.it/bE35Ld)
- [SourceForge](https://kutt.it/69oMi9)

## Troubleshootings
- Command-line for check optimization (with module installed):
```
> su
> gmsc
```
- Command-line for check optimization (in general):   
There's a line written `Whitelist (except idle) system apps:` and if `com.google.android.gms` line does not exist it means Google Play services is optimized).
```
> su
> dumpsys deviceidle
```
- Command-line for check optimization on Android 14+:
```
> su
> dumpsys deviceidle sys-whitelist
```
If `com.google.android.gms` is not listed, Google Play services is optimized.
- Command-line for fix delayed incoming messages issue:   
If the issue still persist, move the app to Not Optimized battery usage.
```
> su
> cd /data/data
> find . -type f -name '*gms*' -delete
```
- Command-line for disable Find My Device (optional):
```
> su
> pm disable com.google.android.gms/com.google.android.gms.mdm.receivers.MdmDeviceAdminReceiver
```

## Credits
- topjohnwu / Magisk - Magisk Module Template
- JumbomanXDA, MrCarb0n / Script fixer and helper

## Extras
- Donations: [PayPal](https://paypal.me/gloeyisk) - [LiberaPay](https://liberapay.com/gloeyisk) - [Ko-fi](https://ko-fi.com/gloeyisk)
- Source Code: [GitHub](https://github.com/gloeyisk/universal-gms-doze)
- Support Thread: [XDA Developers](https://forum.xda-developers.com/apps/magisk/module-universal-gms-doze-t3853710)
