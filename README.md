# OneCloud ImmortalWrt

玩客云（Thunder OneCloud，Amlogic S805 / meson8b，32 位）的 ImmortalWrt 固件。

源码固定为 [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) 的 `v25.12.2` 正式发布版（提交 `4fc16f2985a358bd43bb522e43f05395fcbd6ed5`），保留该标签固定的 feeds。设备支持（设备树、6.12 内核补丁、镜像打包）由本仓库的 `target/linux/amlogic` 提供。

固件和构建工具使用两条独立的 Actions 工作流，每月 1 号自动构建，分别发布到 [Releases](../../releases)。

## 下载哪个文件

| 文件 | 什么时候用 |
| --- | --- |
| `*-emmc.burn.img.xz` | 第一次刷机，或者刷坏了要救砖 |
| `*-sysupgrade.img.gz` | 已经装好了，之后每次升级 |

## 第一次刷机

玩客云出厂只认晶晨的 USB 刷机协议，也没有 TF 卡槽。现在跑的如果是 Armbian，eMMC 里虽然已经有 u-boot，**最省事仍是再线刷一次** OpenWrt 的 burn 包（覆盖 u-boot + 系统）。U 盘安装路径见下面；引导顺序是 eMMC → USB，eMMC 里还有 Armbian 时插 U 盘也进不去 OpenWrt。

1. 解压 `*-emmc.burn.img.xz`
2. 装 [Amlogic USB Burning Tool](https://androiddatahost.com/khfj4)，导入镜像
3. 拆机，短接主板上的刷机触点（或按住机内的小按钮），用双公头 USB 线接电脑，通电
4. 点开始，等进度走完

红灯闪 = 正在启动，蓝灯呼吸 = 已经起来了。第一次启动要多等几分钟：**根分区会自动扩容到整块 eMMC**，扩完会自己重启一次，之后才是正常启动（8GB 机器不用再跑任何脚本）。

启动完成后浏览器打开 `http://10.10.10.1`。

## 之后怎么升级

这是这个仓库存在的主要理由：**刷过一次之后就不用再拆机线刷了。**

就是传统的 OpenWrt 网页升级。LuCI → 系统 → 备份/升级 → 刷写新的固件，选 `*-sysupgrade.img.gz`。或者命令行：

```bash
sysupgrade -v /tmp/immortalwrt-*-sysupgrade.img.gz
```

升级只写引导分区和根分区，**不碰 u-boot**，所以升级失败也不会变砖，大不了再线刷一次。勾选「保留配置」会把 `/etc` 备份带到新系统里。

## 从 U 盘装进 eMMC

已经有 u-boot、并且能从 U 盘启动时（eMMC 里没有可启动系统，或你在 u-boot 里手动指定了 USB），可以把镜像写进 U 盘再装到 eMMC：

```bash
# 电脑上：把镜像写进 U 盘
gzip -dc immortalwrt-*-sysupgrade.img.gz | sudo dd of=/dev/sdX bs=4M status=progress

# 插上 U 盘开机，进系统后：
onecloud-install-emmc
```

引导脚本的顺序是 eMMC → SD → USB。eMMC 里已经有能启动的系统时不会走 U 盘。从 Armbian 换过来请用上面的线刷，不要走这条。

## 默认配置

| 项 | 值 |
| --- | --- |
| LAN | `10.10.10.1/24` |
| 用户名 / 密码 | `root` / `password`（请尽快改） |
| 主机名 | `OneCloud` |
| 时区 | `Asia/Tokyo`（JST-9，不是上海） |
| Reset 键 | 开机过程中按一下进 failsafe；开机后按住约 5 秒恢复出厂 |
| Web 界面 | ImmortalWrt LuCI，简体中文 |
| 防火墙 | firewall4 / nftables |

玩客云只有一个 100M 网口。想当主路由用的话，WAN 需要插 USB 网卡或者手机 USB 共享网络，固件里已经预置了 `eth1` 的 DHCP WAN 口，插上就能用；不插也不影响 LAN。

## 包含

- ImmortalWrt LuCI + 简体中文
- Docker + Docker Compose + LuCI 管理界面
- HomeProxy（sing-box）
- zram 压缩交换分区、BBR、irqbalance、多核软中断分流
- USB 存储（ext4 / vfat / exfat / ntfs3 / f2fs）
- USB 网卡（RTL8152、AX88179、ASIX、SMSC95xx）、安卓 / iPhone USB 共享网络、4G 上网卡
- 常见 USB 无线网卡（MT7601U、MT76x0U、MT76x2U、RTL8XXXU、RT2800）
- UPnP、ttyd 网页终端

Docker 数据默认放在根分区，升级时会被覆盖。经常用 Docker 的话建议插一个 U 盘或硬盘，在 LuCI 的 Docker 设置里把数据目录指到挂载点上。

## 已知限制

- S805 是 32 位 ARM。Docker 只能跑 `linux/arm/v7` 的镜像，很多只发 `arm64` 的镜像用不了，这是 CPU 决定的。
- 1GB 内存 + 100M 网口。当旁路由 / 软路由 / 轻量 NAS 没问题，别指望跑满千兆。
- 没有内置无线，需要无线得插 USB 网卡。

## 自己编译

在 Actions 中选择工作流 → Run workflow，可以改 LAN IP：

| 工作流文件 | 名称 | 产物 |
| --- | --- | --- |
| `.github/workflows/build.yml` | 构建玩客云 ImmortalWrt 固件 | sysupgrade 升级镜像、burn 线刷镜像 |
| `.github/workflows/build-tools.yml` | 构建玩客云 ImageBuilder 和 ImmortalWrt SDK | 独立 ImageBuilder、SDK、设备默认配置 |

固件流程禁用 `CONFIG_IB` 和 `CONFIG_SDK`；工具流程启用两者并包含本地软件包仓库。工具流程仍需编译工具链、内核和软件包，但只打包工具，不生成 sysupgrade 或 burn 镜像。两条流程使用相同源码、feeds 和软件包配置；匹配固件时请使用同一项目提交和相同的输入参数。

工具 Release 使用 `tools-` 标签前缀，不会覆盖最新固件或被固件清理步骤删除。本地构建脚本仍默认生成固件、ImageBuilder 和 SDK。

本地编译（Linux x86_64，建议空闲磁盘 80G 以上，需安装 OpenWrt 编译依赖）：

```bash
git clone https://github.com/2018nuoyan/onecloud-immortalwrt.git
cd onecloud-immortalwrt
set -o pipefail
JOBS=8 bash scripts/build-local.sh 10.10.10.1 true 2>&1 | tee build.log
```

已部署的开发服务器项目目录为 `/home/nuoyan/onecloud-openwrt`，可直接在该目录运行构建脚本。

脚本在项目的 `openwrt/` 目录克隆固定版本，依次检查配置、准备内核、下载源码并编译，不使用其他现有源码目录。已有 `openwrt/` 必须匹配固定提交。`build.status` 记录退出阶段和退出码；产物位于 `openwrt/bin/targets/amlogic/meson8b/`。本地脚本不执行额外的 USB Burning Tool 镜像打包，该步骤仍由 Actions 执行。

### ImageBuilder 与 SDK

- `immortalwrt-imagebuilder-*.tar.zst`：重组固件，包含此次编译的软件包，不编译新包或内核。
- `immortalwrt-sdk-*.tar.zst`：编译匹配此目标的软件包，不是完整固件源码。
- `onecloud-files.tar.gz`：Actions 发布的设备默认配置文件。

在 Linux x86_64 上解压 ImageBuilder 和 `onecloud-files.tar.gz`，进入 ImageBuilder 目录：

```bash
make info
make image PROFILE=thunder-onecloud \
  PACKAGES="luci luci-ssl luci-app-homeproxy sing-box" \
  FILES=/absolute/path/to/files
```

ImageBuilder 默认包集合不等于本项目完整固件，需在 `PACKAGES` 中列出所需附加软件包；参考发布的 `onecloud.config`。它生成 `sysupgrade.img.gz`，不直接生成 burn 包。不要混用官方 OpenWrt、其他 ImmortalWrt 版本或不同内核 ABI 的软件包，尤其是 `kmod-*`。

SDK 常规用法：

```bash
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make package/<package-name>/compile -j8 V=s
```

## 致谢

- [hzyitc/u-boot-onecloud](https://github.com/hzyitc/u-boot-onecloud)、[hzyitc/AmlImg](https://github.com/hzyitc/AmlImg) — u-boot 和晶晨刷机包打包工具
- [lxhao61/OneCloud-OpenWrt](https://github.com/lxhao61/OneCloud-OpenWrt)、[shiyu1314/openwrt-onecloud](https://github.com/shiyu1314/openwrt-onecloud) — S805 设备树与镜像打包的参考
- [immortalwrt/homeproxy](https://github.com/immortalwrt/homeproxy)

## 许可

GPL-2.0，同 OpenWrt。
