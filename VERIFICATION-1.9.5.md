# Universal GMS Doze 1.9.5 验证记录

验证日期：2026-10-04。设备：小米平板（pipa / 23043RP34C），MIUI 14、Android 13（API 33）、KernelSU，使用 Hybrid Mount 元模块。

- 21 项本地回归检查通过：脚本语法、XML 节点删除和拒绝不安全输入、备份保存和迁移、系统/用户来源区分、恢复成功与失败、启动脚本移除和记录恢复依据、清理确认与取消。
- 已通过 KernelSU 安装并正常重启，实机版本为 1.9.5，名称为 Universal GMS Doze。
- 安装后保留 uninstall.sh 和 restore.sh，product 链接目标存在。
- 实际挂载的 /product/etc/sysconfig/google.xml 与模块覆盖文件 SHA-256 一致，GMS 的两个目标豁免节点移除，其他应用及其他类型节点保留。
- 实机查询完整 Doze 白名单及 except-idle 豁免均返回 false；gmsc 分项输出与直接查询一致。
- 实机 common.sh 和 action.sh 的 SHA-256 与本地源码一致。
- 音量键能力存在；实机模拟超时确认取消，未执行数据清理。确认清理分支只在模拟 pm 服务下验证，未真正清除 GMS 数据。
- 卸载后恢复在模拟服务下验证，未为测试卸载平板上的模块。
- 1.9.4 备份迁移保留旧副本，用户基线取实际当前值 0，系统基线保留 1；无法从旧的混合白名单记录恢复未知的历史用户设置。

安装包：gms_1.9.5.zip，19504 字节。

SHA-256：BA703F6FACA849F18EEEF9D8D6A1C8912CAE58B08860C49434683058AFCAA24D。

未测量长期耗电改善，未验证其他设备、系统和 Root 实现。本记录对应发布前的验证结果。
