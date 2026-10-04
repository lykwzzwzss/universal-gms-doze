# Universal GMS Doze

这是 [gloeyisk/universal-gms-doze](https://github.com/gloeyisk/universal-gms-doze) 的社区维护分支。

## 功能

- 从 Android 的系统电池优化白名单中移除 Google Play 服务。
- 面向 Android 6.0 及以上；不同系统和 Root 实现的兼容性以实际检测结果为准。
- 支持 Magisk、KernelSU 和 APatch。
- 不会自动清除应用数据，也不会修改其他模块的文件。
- GMS 数据清理改为安装后的可选操作。

移除白名单可能导致普通优先级推送、后台同步、定位、Wear OS 连接或其他依赖 GMS 的功能延迟。请先在自己的设备上测试。

## 安装

请从 Magisk、KernelSU 或 APatch 应用安装，不支持从 Recovery 直接安装。安装后必须重启，XML 覆盖才会生效。新版 KernelSU/APatch 如采用元模块挂载，请安装对应的挂载元模块。

## 检查状态

安装并重启后，以 Root 身份执行：

```sh
su
gmsc
```

也可以查看完整列表：

```sh
su
dumpsys deviceidle whitelist
dumpsys deviceidle sys-whitelist
```

`gmsc` 分别报告完整 Doze 豁免、非 Doze 的其他省电豁免和当前深度/轻度休眠状态。`system-excidle` 中出现 GMS 不代表完整 Doze 豁免移除失败；查询失败会显示未知，不会误报成功。高优先级推送仍可能获得临时豁免，本模块不阻止正常临时唤醒。白名单移除和实际省电幅度不是同一回事。

## 可选：清除 GMS 数据

安装时不会清除 GMS 数据。只有在确实遇到推送或同步异常时，才建议主动执行：

- 在 Magisk/KernelSU/APatch 的模块操作按钮中执行 `action.sh`；或
- 以 Root 身份手动运行模块目录中的 `action.sh`。

执行后按音量上键确认清理、下键取消；30 秒超时或无法读取按键时自动取消。仅清除当前前台 Android 用户的 GMS，不遍历其他用户或工作资料。清除数据可能导致账号重新登录、推送令牌重建和本地状态丢失。

## 注意事项

- 本模块不会自动禁用“查找我的设备”或设备管理组件。
- 全新安装会在 XML 覆盖生效前按来源保存白名单状态，升级不会覆盖备份。卸载只恢复原本存在且模块曾移除的用户/系统条目；卸载后下一次开机完成时运行一次恢复任务，成功后自动清理，失败时保留备份重试。
- 从 1.9.4 升级时保留旧备份，但其用户白名单记录无法可靠重建，因此以升级时实际用户白名单为准，不根据错误旧值额外添加用户豁免。
- XML 按节点处理，支持单行、多行、不同属性顺序及单/双引号；不修改注释和其他配置。不能安全解析的文件会跳过并提示。
- 安装生成标准 `system/product`、`system/vendor`、`system/system_ext`、`system/odm` 路径，管理器负责分区调整，避免自行复制和清理导致悬空链接。
- 如果 GMS 原本就不在系统白名单中，安装本模块通常不会带来明显收益。

## 下载

- [GitHub Releases](https://github.com/lykwzzwzss/universal-gms-doze/releases)

## 许可证

GPL-2.0，详见 [LICENSE](LICENSE)。
