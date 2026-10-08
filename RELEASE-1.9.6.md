# Universal GMS Doze 1.9.6

本版将状态检测工具留在模块内部，不再向 `/system/bin` 注入 `gmsc`，保留 GMS 白名单移除功能。

同时修复已挂载旧 XML 时升级丢失覆盖的问题；为系统调用增加超时和强制结束保护；减少已优化设备的重复启动查询；加强异常状态、备份校验、可选清理和卸载恢复的稳定性。

模块名称为 Universal GMS Doze，ID 不变。默认不清理数据，主动清理仍需音量上键确认，下键或超时取消，只针对当前 Android 用户。

## 升级与查询

从管理器安装 `gms_1.9.6.zip` 后必须重启，旧的 `/system/bin/gmsc` 挂载才会退出。重启后以 Root 身份运行：

```sh
su
sh /data/adb/modules/universal-gms-doze/gmsc
```

不要手动删除真实系统文件。此更改不承诺隐藏全部模块痕迹，也不更改其他框架模块的“禁用 umount”依赖。

## 验证范围

本版完成静态审查，49 项本地回归检查通过。详细发现及限制见 [静态审查报告](https://github.com/lykwzzwzss/universal-gms-doze/blob/1.9.6/REVIEW-1.9.6.md) 和 [验证记录](https://github.com/lykwzzwzss/universal-gms-doze/blob/1.9.6/VERIFICATION-1.9.6.md)。没有完成 1.9.6 的平板安装重启、通知兼容性或长期耗电实测，不提供省电百分比保证。出现异常时请正常卸载并重启恢复，单纯禁用不会执行卸载恢复。

安装包：`gms_1.9.6.zip`，23181 字节。

SHA-256：`8D68EB8EBDC0C4B124FA8E5E93661F32E4A173BA6F85A99D215E792F23772403`。
