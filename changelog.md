## 1.9.4

- 移除安装时自动删除 `/data/data` 下所有 `*gms*` 文件的危险行为。
- 将 GMS 数据清理改为可选的 `action.sh` 操作，并限定为清理 `com.google.android.gms` 数据。
- 停止修改其他模块拥有的 XML 文件。
- 增加 `allow-in-power-save-except-idle` XML 条目的处理。
- 保存安装前的 GMS 白名单状态，卸载时只恢复模块实际涉及的项目。
- 不再自动禁用 GMS 的设备管理组件。
- 更新 `gmsc`，同时检查用户白名单、系统白名单和 except-idle 白名单。
- 将模块提示、说明和变更记录改为中文。
- 将启动检查轮询间隔从 100 秒缩短为 10 秒。

## 1.9.3

- 支持 Android 16 和 Android 17。
- 修复 Android 14+ 上 GMS 从系统电池优化白名单移除不生效的问题。
- 支持单引号和双引号 XML 包属性。
- 修复 `/product` 与 `/system/product` 指向同一文件时的安装合并问题。
- 修复卸载脚本语法问题。

其余历史记录请参考上游项目的提交记录。
