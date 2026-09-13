# 通用 GMS Doze

这是 [gloeyisk/universal-gms-doze](https://github.com/gloeyisk/universal-gms-doze) 的社区维护分支。

## 功能

- 从 Android 的系统电池优化白名单中移除 Google Play 服务。
- 支持 Android 6.0 至 Android 17（API 23-37）。
- 支持 Magisk、KernelSU 和 APatch。
- 不会自动清除应用数据，也不会修改其他模块的文件。
- GMS 数据清理改为安装后的可选操作。

移除白名单可能导致普通优先级推送、后台同步、定位、Wear OS 连接或其他依赖 GMS 的功能延迟。请先在自己的设备上测试。

## 安装

请从 Magisk 或 KernelSU 应用安装，不支持从 Recovery 直接安装。

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

如果 `com.google.android.gms` 出现在任意相关列表中，说明它仍然豁免了部分电池优化。

## 可选：清除 GMS 数据

安装时不会清除 GMS 数据。只有在确实遇到推送或同步异常时，才建议主动执行：

- 在 Magisk/KernelSU 的模块操作按钮中执行 `action.sh`；或
- 以 Root 身份手动运行模块目录中的 `action.sh`。

清除数据可能导致 Google 账号重新登录、推送令牌重建，并删除本地状态。不要使用按文件名删除 `/data/data` 文件的方式清理。

## 注意事项

- 本模块不会自动禁用“查找我的设备”或设备管理组件。
- 卸载时只恢复模块安装前原本存在的 GMS 白名单项目。
- 如果 GMS 原本就不在系统白名单中，安装本模块通常不会带来明显收益。

## 下载

- [GitHub Releases](https://github.com/lykwzzwzss/universal-gms-doze/releases)

## 许可证

GPL-2.0，详见 [LICENSE](LICENSE)。
