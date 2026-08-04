# OpenWRT-CI

自用 ImmortalWrt 云编译流程。

## 设备

- 京东云太乙 ER1 / `jdcloud_re-cs-07`：`qualcommax/ipq60xx`，保留满血 NSS 加速。
- 友善 NanoPi R76S / `friendlyarm_nanopi-r76s`：`rockchip/armv8`。
- x86_64 / generic。

## 默认设置

- 默认登录 IP：`192.168.100.1`
- 默认主题：Argon
- rootfs 分区：`2048MB`
- LuCI 中文

## 内置插件

Argon + Argon Config、Docker / Dockerman、DiskMan、QuickFile、UPnP、netspeedtest、Momo、nikki、OpenList2、BBR、FullCone、RTL8168 / RTL8152。

R76S 额外包含 RTL8125、rtl8822cs、hci-uart、Rockchip DRM / Panfrost / rkvdec / rocket-rockchip，并自动加入：

- `40-net-smp-affinity`
- sbwml R76S packet steering patch

## kmod 软件源

编译时启用全量 kmod / nonshared 包构建，并在 Release 中额外发布：

- `Packages-*.tar.zst`：`bin/packages` 全量包。
- `Kmods-*.tar.zst`：目标平台 `bin/targets/*/*/packages` 内核模块包。

方便使用者自建 kmod 软件源，避免部分依赖 kmod 的软件无法安装。

## 源码

- 默认源码：`VIKINGYFY/immortalwrt`
- ER1 默认分支：`main`
- R76S / x86 默认分支：`owrt`
