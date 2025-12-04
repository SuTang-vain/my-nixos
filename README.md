# my-nixos

## 近期主要变更 (2025-12-04)

本次更新将系统配置迁移到了现代化的、基于 Flakes 的管理方式，并集成了 `Noctalia` 桌面 Shell。

### 详细变更步骤：

1.  **修复 `clash-verge` TUN 模式问题**
    *   将 `clash-verge-rev` 的安装方式从 `environment.systemPackages` 修改为使用 `programs.clash-verge` 模块，从根本上解决了 TUN 虚拟网卡所需的权限问题。

2.  **架构重构：迁移到 Flakes**
    *   创建了 `flake.nix` 文件，使整个 NixOS 系统配置由 Flakes 进行管理，提高了可复现性。
    *   将 `nixpkgs` 分支切换到 `nixos-unstable`，以满足 `Noctalia` 对新版本软件包的依赖。

3.  **引入 Home Manager**
    *   在 `flake.nix` 中添加了 `home-manager` 模块。
    *   创建了 `home.nix` 文件，用于专门管理用户 `sutang` 的个人环境和软件包。
    *   原 `configuration.nix` 中的用户级软件包 (`kate`) 已迁移至 `home.nix`。

4.  **集成 Noctalia Shell**
    *   根据官方教程，创建了 `完善NixOS配置计划.md` 作为行动指南。
    *   在 `configuration.nix` 中添加了 `Noctalia` 所需的系统级依赖（如 `upower`, `bluetooth`）以及 `Niri` 窗口合成器。
    *   在 `home.nix` 中配置 `Noctalia`，使其作为软件包安装，并设置为在 `Niri` 会话启动时自动运行。

### 当前文件结构：

-   `flake.nix`: 系统配置入口，管理所有依赖（nixpkgs, home-manager, noctalia）。
-   `configuration.nix`: 系统级配置。
-   `home.nix`: 用户 `sutang` 的个人环境配置。
-   `hardware-configuration.nix`: 系统硬件配置。
-   `完善NixOS配置计划.md`: 本次配置升级的详细规划文档。

现在，您可以在目标机器上通过 `sudo nixos-rebuild switch --flake .` 来部署这套配置。
