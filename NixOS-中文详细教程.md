# NixOS 上的 Noctalia 安装配置详细教程

## 概述

Noctalia 是一个基于 Quickshell 的现代化桌面 Shell，专为 Wayland compositor 设计。本教程将详细介绍如何在 NixOS 系统上安装和配置 Noctalia。

**重要前提条件：**
- Noctalia 的 flake 需要使用 **nixpkgs unstable** 分支，因为它依赖于最新版本的 Quickshell
- 需要支持 Wayland 的桌面环境（如 Niri、Hyprland、Sway 等）
- 推荐使用 NixOS 22.11 或更新版本

---

## 第一步：系统依赖项配置

在开始安装 Noctalia 之前，您需要确保系统中启用了以下基本服务和模块，这些是 Noctalia 核心功能正常运行所必需的：

### 必需的系统选项

在您的 NixOS 配置文件中（通常是 `/etc/nixos/configuration.nix` 或通过 flake 管理的配置），确保启用了以下选项：

```nix
# 网络管理（WiFi 功能必需）
networking.networkmanager.enable = true;

# 蓝牙支持
hardware.bluetooth.enable = true;

# 电源配置文件管理器（电池和电源管理功能必需）
# 选择其中一种：
services.power-profiles-daemon.enable = true;
# 或者使用 tuned
services.tuned.enable = true;

# UPower 服务（电池状态监控）
services.upower.enable = true;
```

**配置说明：**
- **NetworkManager**：提供网络连接管理，Noctalia 的 WiFi 小部件需要此服务
- **蓝牙模块**：启用蓝牙硬件支持，Noctalia 的蓝牙小部件依赖于此
- **电源配置守护进程**：管理不同电源配置文件（平衡、省电、高性能）
- **UPower**：提供电池状态信息，是电池小部件正常工作的基础

### 应用配置

修改配置后，重新构建系统：

```bash
sudo nixos-rebuild switch
```

---

## 第二步：添加 Flake 输入

### 2.1 理解 Flake 结构

在 NixOS 中，Flake 是一种新的包管理机制，允许您声明式地管理 Nix 依赖项。我们需要将 Noctalia 添加为 flake 输入。

### 2.2 配置 flake.nix

创建或编辑您项目根目录下的 `flake.nix` 文件：

```nix
{
  description = "我的 NixOS 配置，包含 Noctalia Shell";

  # 定义外部依赖项输入源
  inputs = {
    # NixOS 包集合，使用不稳定分支（需要最新 Quickshell）
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Noctalia flake 输入
    # 跟随 nixpkgs 输入，保持版本同步
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # 定义输出函数
  outputs = inputs@{ self, nixpkgs, ... }: {
    # 生成 NixOS 配置
    # 注意：'awesomebox' 需要替换为您的 hostname
    nixosConfigurations.awesomebox = nixpkgs.lib.nixosSystem {
      modules = [
        # 其他系统模块
        # ./hardware-configuration.nix  # 如果有硬件配置
        # ./home-manager.nix            # 如果使用 home-manager

        # 引入 Noctalia 模块
        ./noctalia.nix
      ];
    };
  };
}
```

**配置详解：**
- **description**：flake 的描述信息
- **inputs**：定义了外部依赖
  - `nixpkgs.url`：指定使用 NixOS 不稳定分支
  - `noctalia`：Noctalia 项目的 GitHub 地址
  - `inputs.nixpkgs.follows = "nixpkgs"`：确保 Noctalia 使用与系统相同的 nixpkgs 版本
- **outputs**：定义输出，这里生成 NixOS 配置
- **nixosConfigurations**：NixOS 配置定义
  - `awesomebox`：需要替换为您的实际 hostname

### 2.3 更新 Flake 锁定

在添加或修改 flake 输入后，需要锁定依赖项版本：

```bash
# 锁定并更新 flake
nix flake lock

# 验证 flake 配置是否正确
nix flake show
```

---

## 第三步：安装 Noctalia 包

### 3.1 创建配置模块文件

创建 `noctalia.nix` 文件：

```nix
{ pkgs, inputs, ... }:
{
  # 安装系统级包
  environment.systemPackages = with pkgs; [
    # 安装 Noctalia 主包
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

    # 可选：安装额外工具
    # jq          # JSON 处理工具（Noctalia 配置需要）
    # colordiff   # 彩色差异显示
  ];

  # 可选：添加系统环境变量
  environment.sessionVariables = {
    # 如果需要添加环境变量，在这里定义
    # NOCTALIA_DEBUG = "1";
  };
}
```

**参数说明：**
- `{ pkgs, inputs, ... }`：函数参数
  - `pkgs`：nixpkgs 实例
  - `inputs`：所有 flake 输入
  - `...`：其他参数
- **environment.systemPackages**：系统级软件包列表
- **${pkgs.stdenv.hostPlatform.system}**：获取当前系统架构（如 x86_64-linux）

### 3.2 重新构建系统

```bash
# 使用 flake 重新构建系统
sudo nixos-rebuild switch --flake .

# 构建并切换到新配置
# --flake . 指定当前目录的 flake 配置
```

**等待构建完成**，这可能需要几分钟时间，具体取决于您的网络速度和系统性能。

### 3.3 验证安装

安装完成后，可以检查 Noctalia 是否正确安装：

```bash
# 检查可执行文件
which noctalia-shell

# 查看版本信息（如果支持）
noctalia-shell --version

# 列出 flake 包
nix flake show github:noctalia-dev/noctalia-shell
```

---

## 第四步：使用 Home Manager 配置

### 4.1 启用 Home Manager

Home Manager 是管理用户级配置和应用程序的工具。建议使用它来管理 Noctalia 配置。

#### 方式一：通过 Flake 集成（推荐）

在 `flake.nix` 中添加 home-manager 输入：

```nix
{
  description = "我的 NixOS + Home Manager 配置";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 添加 home-manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    # NixOS 配置
    nixosConfigurations.awesomebox = nixpkgs.lib.nixosSystem {
      modules = [
        # 启用 home-manager 模块
        inputs.home-manager.nixosModules.home-manager

        ./noctalia.nix
        ./home-manager.nix  # Home Manager 配置
      ];
    };

    # Home Manager 配置（独立生成）
    homeConfigurations."drfoobar@awesomebox" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      homeDirectory = "/home/drfoobar";
      username = "drfoobar";
      modules = [
        ./noctalia-home.nix  # Noctalia Home Manager 配置
      ];
    };
  };
}
```

#### 方式二：独立安装

```bash
# 安装 home-manager 到用户环境
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

# 在 shellrc 中添加（~/.bashrc 或 ~/.zshrc）
export NIX_PATH="$HOME/.nix-defexpr/channels:$NIX_PATH"
```

### 4.2 基础配置

创建 `noctalia-home.nix`：

```nix
{ pkgs, inputs, ... }:
{
  # 导入 Home Manager 模块
  imports = [
    # Noctalia Home Manager 模块
    inputs.noctalia.homeModules.default
  ];

  # 配置 Home Manager 用户
  home.username = "drfoobar";           # 替换为您的用户名
  home.homeDirectory = "/home/drfoobar"; # 替换为您的家目录

  # 启用 Night Light 等功能
  programs.home-manager.enable = true;

  # 启用 Noctalia
  programs.noctalia-shell = {
    enable = true;

    # 基础设置
    settings = {
      # 设置版本（保持与实际版本一致）
      settingsVersion = 25;

      # 条形栏配置
      bar = {
        # 位置：top, bottom, left, right
        position = "top";

        # 透明度（0-1）
        backgroundOpacity = 1;

        # 密度：default, compact
        density = "default";

        # 是否显示胶囊形状
        showCapsule = true;

        # 是否外角（圆角）
        outerCorners = true;

        # 小部件配置
        widgets = {
          # 左侧小部件
          left = [
            {
              id = "ControlCenter";  # 控制中心按钮
            }
            {
              id = "SystemMonitor";  # 系统监控器
            }
            {
              id = "ActiveWindow";   # 活动窗口
            }
            {
              id = "MediaMini";      # 媒体控制（迷你）
            }
          ];

          # 中央小部件
          center = [
            {
              id = "Workspace";      # 工作区切换器
            }
          ];

          # 右侧小部件
          right = [
            {
              id = "ScreenRecorder"; # 屏幕录制
            }
            {
              id = "Tray";           # 系统托盘
            }
            {
              id = "NotificationHistory"; # 通知历史
            }
            {
              id = "Battery";        # 电池
            }
            {
              id = "Volume";         # 音量
            }
            {
              id = "Brightness";     # 亮度
            }
            {
              id = "Clock";          # 时钟
            }
          ];
        };
      };

      # 常规设置
      general = {
        # 用户头像图片路径
        avatarImage = "";  # 例如："/home/drfoobar/.face"

        # 调暗器透明度
        dimmerOpacity = 0.6;

        # 缩放比例
        scaleRatio = 1;

        # 圆角半径比例
        radiusRatio = 1;

        # 动画速度
        animationSpeed = 1;

        # 锁定屏幕时挂起
        lockOnSuspend = true;

        # 启用阴影
        enableShadows = true;
      };

      # 位置和天气设置
      location = {
        # 城市名称
        name = "Tokyo";

        # 启用天气
        weatherEnabled = true;

        # 使用华氏度
        useFahrenheit = false;

        # 使用 12 小时格式
        use12hourFormat = false;

        # 显示日历事件
        showCalendarEvents = true;

        # 显示天气信息
        showCalendarWeather = true;
      };

      # 通知配置
      notifications = {
        enabled = true;
        # 位置：top_left, top_right, bottom_left, bottom_right
        location = "top_right";
      };

      # 音量设置
      audio = {
        # 音量步长（百分比）
        volumeStep = 5;
        # 音频可视化器类型
        visualizerType = "linear";
      };

      # 亮度设置
      brightness = {
        # 亮度步长（百分比）
        brightnessStep = 5;
      };
    };

    # 可选：启用 systemd 服务
    # systemd.enable = true;
  };

  # 可选：启用一些有用的包
  home.packages = with pkgs; [
    jq                    # JSON 处理工具
    colordiff             # 彩色 diff 工具
  ];
}
```

### 4.3 应用 Home Manager 配置

```bash
# 切换到新配置
home-manager switch

# 如果使用 flake 方式
nix run github:nix-community/home-manager -- switch --flake .
```

### 4.4 验证 Home Manager 配置

```bash
# 查看生成的配置文件
ls -la ~/.config/noctalia/

# 检查配置文件语法
jq . ~/.config/noctalia/settings.json

# 列出 Home Manager 历史
home-manager generations
```

---

## 第五步：主题颜色配置

### 5.1 Material 3 颜色主题

Noctalia 使用 Material Design 3 颜色规范。您可以自定义所有颜色：

```nix
programs.noctalia-shell = {
  enable = true;
  colors = {
    # 主色调
    mPrimary = "#aaaaaa";        # 主色
    mOnPrimary = "#111111";      # 主色上文字颜色

    # 次要色调
    mSecondary = "#a7a7a7";      # 次要色
    mOnSecondary = "#111111";    # 次要色上文字颜色

    # 错误色
    mError = "#dddddd";          # 错误背景
    mOnError = "#111111";        # 错误文字

    # 表面色
    mSurface = "#111111";        # 表面背景
    mOnSurface = "#828282";      # 表面文字
    mSurfaceVariant = "#191919"; # 表面变体
    mOnSurfaceVariant = "#5d5d5d"; # 表面变体文字

    # 三级色
    mTertiary = "#cccccc";       # 三级色
    mOnTertiary = "#111111";     # 三级色文字

    # 悬停状态
    mHover = "#1f1f1f";          # 悬停背景
    mOnHover = "#ffffff";        # 悬停文字

    # 边框和阴影
    mOutline = "#3c3c3c";        # 边框色
    mShadow = "#000000";         # 阴影色
  };
};
```

**颜色配置注意事项：**
- **必须设置所有颜色**：覆盖默认值时，必须设置所有 Material 3 颜色变量
- **保持对比度**：确保文字颜色与背景有足够对比度
- **颜色格式**：使用十六进制颜色码（#RRGGBB 或 #RRGGBBAA）
- **测试所有状态**：检查正常、悬停、选中、禁用等状态的配色

### 5.2 预设主题

使用预设的配色方案：

```nix
programs.noctalia-shell = {
  enable = true;
  settings = {
    colorSchemes = {
      # 使用预设主题
      # 选项：Noctalia (default), Monochrome, Rainbow, Fruit Salad 等
      predefinedScheme = "Monochrome";

      # 深色模式
      darkMode = true;

      # 调度模式：off, system, manual, matugen
      schedulingMode = "off";
    };
  };
};
```

### 5.3 从壁纸提取颜色

使用工具从壁纸自动生成配色：

```nix
programs.noctalia-shell = {
  enable = true;
  settings = {
    colorSchemes = {
      # 从壁纸提取颜色
      useWallpaperColors = true;

      # Matugen 方案类型
      matugenSchemeType = "scheme-fruit-salad";  # 水果沙拉色系
      # 其他选项：scheme-monochrome, scheme-neutral, scheme-vibrant
    };
  };
};
```

---

## 第六步：按键绑定配置

### 6.1 理解 IPC 调用

Noctalia 通过 IPC（进程间通信）接受命令。您可以通过命令行或 compositor 的快捷键调用：

```bash
# 基本语法
noctalia-shell ipc call <命令> <参数>

# 示例
noctalia-shell ipc call launcher toggle        # 切换启动器
noctalia-shell ipc call sessionMenu toggle     # 切换会话菜单
noctalia-shell ipc call lockScreen toggle      # 切换锁屏
```

### 6.2 Niri Compositor 快捷键

在 Niri 中安全地配置快捷键（使用列表格式）：

```nix
{ pkgs, inputs, ... }:

let
  # Noctalia 辅助函数：生成命令列表
  noctalia = cmd: [
    "noctalia-shell" "ipc" "call"
  ] ++ (pkgs.lib.splitString " " cmd);
in
{
  home-manager.users.drfoobar = {
    programs.niri = {
      settings = {
        # 窗口管理器快捷键
        binds = with config.lib.niri.actions; {
          # Mod 键 = Super/Win 键

          # 应用启动器
          "Mod+Space".action.spawn = [
            "noctalia-shell" "ipc" "call" "launcher" "toggle"
          ];

          # 会话菜单
          "Mod+Shift+S".action.spawn = noctalia "sessionMenu toggle";

          # 锁定屏幕
          "Mod+L".action.spawn = noctalia "lockScreen toggle";

          # 控制中心
          "Mod+C".action.spawn = noctalia "controlCenter toggle";

          # 音量控制
          "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
          "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
          "XF86AudioMute".action.spawn = noctalia "volume muteOutput";

          # 亮度控制
          "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
          "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";

          # 媒体控制
          "XF86AudioPlay".action.spawn = noctalia "media toggle";
          "XF86AudioNext".action.spawn = noctalia "media next";
          "XF86AudioPrev".action.spawn = noctalia "media previous";
        };
      };
    };
  };
}
```

**按键绑定说明：**
- **"Mod+Space"**：Win/Ctrl + 空格（应用启动器）
- **"Mod+L"**：Win/Ctrl + L（锁定屏幕）
- **"XF86Audio"**：媒体键（笔记本键盘或外接键盘）
- **使用函数**：定义 `noctalia` 函数简化命令构建
- **正确格式**：使用列表形式 `["command", "arg1", "arg2"]`

### 6.3 Hyprland 快捷键

在 Hyprland 中的配置示例：

```nix
{ pkgs, ... }:

{
  # ...

  programs.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER";  # Win 键
      binds = {
        # 启动器
        "$mod, SPACE, exec, noctalia-shell ipc call launcher toggle";

        # 锁定屏幕
        "$mod, L, exec, noctalia-shell ipc call lockScreen toggle";

        # 音量
        ", XF86AudioLowerVolume, exec, noctalia-shell ipc call volume decrease";
        ", XF86AudioRaiseVolume, exec, noctalia-shell ipc call volume increase";
      };
    };
  };
}
```

### 6.4 Sway 快捷键

在 Sway 中的配置：

```nix
{
  # ...

  programs.sway = {
    enable = true;

    config = {
      # 按键绑定
      keybindings = [
        # 启动器
        "Mod+Space exec noctalia-shell ipc call launcher toggle"

        # 锁定
        "Mod+Lock exec noctalia-shell ipc call lockScreen toggle"
      ];
    };
  };
}
```

### 6.5 常用 IPC 命令

| 功能 | 命令 | 描述 |
|------|------|------|
| 启动器 | `launcher toggle` | 显示/隐藏应用启动器 |
| 会话菜单 | `sessionMenu toggle` | 显示/隐藏电源菜单 |
| 锁屏 | `lockScreen toggle` | 锁定/解锁屏幕 |
| 控制中心 | `controlCenter toggle` | 显示/隐藏控制中心 |
| 音量 | `volume decrease/increase/muteOutput` | 降低/升高/静音 |
| 亮度 | `brightness increase/decrease` | 调整亮度 |
| 媒体 | `media toggle/next/previous` | 播放/暂停/下一首/上一首 |
| 工作区 | `workspace prev/next` | 上一个/下一个工作区 |

---

## 第七步：运行 Noctalia

### 7.1 手动运行

最简单的方式是直接运行：

```bash
# 启动 Noctalia
noctalia-shell
```

**测试运行：**
```bash
# 后台运行（如果需要）
nohup noctalia-shell &

# 查看进程
ps aux | grep noctalia-shell

# 查看日志
journalctl -u noctalia-shell
```

### 7.2 配置开机自启动

#### 在 Niri 中配置自启动

```nix
{ pkgs, inputs, ... }:

{
  # ...

  home-manager.users.drfoobar = {
    programs.niri = {
      # 使用 Niri flake
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.default;

      settings = {
        # 配置自启动应用
        spawn-at-startup = [
          {
            command = [
              "noctalia-shell"
            ];
          }

          # 其他自启动应用
          {
            command = [ "waybar" ];  # 可选：状态栏
          }
        ];
      };
    };
  };
}
```

#### 通用自启动脚本

创建 `~/.config/noctalia/autostart.sh`：

```bash
#!/bin/bash
# Noctalia 自启动脚本

# 等待 compositor 完全加载
sleep 1

# 启动 Noctalia
noctalia-shell

# 其他自启动命令
# waybar &
# dunst &  # 通知守护进程
```

在 composior 配置中执行此脚本：

```nix
# 在 Niri 中
programs.niri.settings.exec-on-start = [
  "bash ~/.config/noctalia/autostart.sh"
];

# 在 Hyprland 中
programs.hyprland.settings.exec-on-start = [
  "bash ~/.config/noctalia/autostart.sh"
];
```

### 7.3 使用 Systemd 服务

#### NixOS 系统级服务

**优势：**
- 系统级集成
- 自动重启
- 开机自启

**劣势：**
- 需要 root 权限
- 配置较复杂

在 `noctalia.nix` 中：

```nix
{ pkgs, inputs, ... }:
{
  # 导入 NixOS 模块
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  # 启用 systemd 服务
  services.noctalia-shell = {
    enable = true;

    # 可选：自定义目标
    target = "graphical-session.target";
    # 其他选项：my-hyprland-session.target

    # 可选：环境变量
    environment = {
      NOCTALIA_DEBUG = "1";
    };
  };
}
```

**使用说明：**
- 服务默认在 `graphical-session.target` 启动
- 适用于 Niri 和 Hyprland（使用 UWSM）
- 如果使用自定义目标，需要确保目标存在

#### Home Manager 用户服务

在 `noctalia-home.nix` 中：

```nix
{ pkgs, inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;

    # 启用 systemd 用户服务
    systemd.enable = true;

    # 自定义目标（可选）
    systemd.target = "wayland-session.target";
  };
}
```

**使用说明：**
- 用户级服务（无需 root）
- 通过 Home Manager 管理
- 目标由 Home Manager 的 `wayland.systemd.target` 决定

#### Systemd 服务管理命令

```bash
# 启动服务
sudo systemctl start noctalia-shell    # 系统级
systemctl --user start noctalia-shell  # 用户级

# 启用开机自启
sudo systemctl enable noctalia-shell
systemctl --user enable noctalia-shell

# 查看状态
sudo systemctl status noctalia-shell
systemctl --user status noctalia-shell

# 查看日志
sudo journalctl -u noctalia-shell
journalctl --user -u noctalia-shell

# 重新加载配置
sudo systemctl daemon-reload
systemctl --user daemon-reload

# 重启服务
sudo systemctl restart noctalia-shell
systemctl --user restart noctalia-shell

# 停止服务
sudo systemctl stop noctalia-shell
systemctl --user stop noctalia-shell

# 禁用服务
sudo systemctl disable noctalia-shell
systemctl --user disable noctalia-shell
```

**注意事项：**
- **实验性功能**：systemd 服务目前为实验性功能
- **避免重复启用**：不要同时在 NixOS 和 Home Manager 模块中启用服务
- **Hyprland 支持**：在 Hyprland 上的新功能测试尚不完整
- **故障排除**：遇到问题请查看日志或提交 issue

---

## 第八步：日历事件支持

### 8.1 安装 Evolution Data Server

Noctalia 支持通过 Evolution Data Server 显示日历事件：

在 `noctalia.nix` 中：

```nix
{ pkgs, inputs, ... }:
{
  # 启用 Evolution 数据服务器
  services.gnome.evolution-data-server.enable = true;

  # 安装 Python 绑定
  environment.systemPackages = with pkgs; [
    (python3.withPackages (pyPkgs: with pyPkgs; [
      pygobject3  # PyGObject3 绑定
    ]))
  ];

  # 设置 GI 类型库路径
  environment.sessionVariables = {
    # 为 Python GObject 绑定设置库路径
    GI_TYPELIB_PATH = pkgs.lib.makeSearchPath "lib/girepository-1.0" (
      with pkgs;
      [
        evolution-data-server
        libical
        glib.out
        libsoup_3
        json-glib
        gobject-introspection
      ]
    );
  };

  # 可选：启用 Evolution 日历
  services.evolution-data-server.enable = true;
}
```

**服务说明：**
- **Evolution Data Server**：提供日历和联系人数据存储
- **PyGObject3**：Python 绑定，用于访问 Evolution 数据
- **GI_TYPELIB_PATH**：GObject 内省类型库路径
- **依赖包**：
  - `libical`：iCalendar 库
  - `libsoup_3`：HTTP 客户端库
  - `json-glib`：JSON 处理库
  - `gobject-introspection`：GObject 内省支持

### 8.2 配置日历

安装完成后，重新构建系统：

```bash
sudo nixos-rebuild switch
```

然后在 Noctalia 中：
1. 打开控制中心
2. 进入日历
3. 添加日历源（Google Calendar、CalDAV、本地日历等）

### 8.3 常用日历配置

#### Google Calendar

```bash
# 安装 OAuth 工具
nix-env -iA nixpkgs.gnumed # 或者其他工具

# 通过 GUI 添加：
# 控制中心 → 日历 → 添加 → Google Calendar
```

#### CalDAV 服务器

```bash
# 配置示例：
# 服务器：https://caldav.example.com
# 用户名：your-username
# 密码：your-password
```

---

## 第九步：完整配置参考

### 9.1 完整设置示例

```nix
{ pkgs, inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;

    # 基础配置
    settings = {
      settingsVersion = 25;

      # ===== 条形栏 =====
      bar = {
        position = "top";
        backgroundOpacity = 1;
        density = "compact";  # 紧凑模式
        showCapsule = false;  # 禁用胶囊形状
        floating = false;     # 不浮动
        marginVertical = 0.25;
        marginHorizontal = 0.25;
        outerCorners = true;
        exclusive = true;     # 独占区域

        widgets = {
          # 左侧：侧边面板切换、WiFi、蓝牙
          left = [
            {
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
          ];

          # 中央：工作区
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";  # 不显示标签
            }
          ];

          # 右侧：电池、时钟
          right = [
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;  # 30% 时警告
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;  # 等宽字体
              usePrimaryColor = true;    # 使用主色
            }
          ];
        };
      };

      # ===== 常规设置 =====
      general = {
        avatarImage = "/home/drfoobar/.face";
        dimmerOpacity = 0.6;
        showScreenCorners = false;
        forceBlackScreenCorners = false;
        scaleRatio = 1;
        radiusRatio = 0.2;  # 较小圆角
        screenRadiusRatio = 0.1;
        animationSpeed = 1;
        animationDisabled = false;
        compactLockScreen = false;
        lockOnSuspend = true;
        showHibernateOnLockScreen = false;
        enableShadows = true;
        shadowDirection = "bottom_right";
        shadowOffsetX = 2;
        shadowOffsetY = 3;
        language = "";  # 自动检测
        allowPanelsOnScreenWithoutBar = true;
      };

      # ===== 用户界面 =====
      ui = {
        fontDefault = "Roboto";
        fontFixed = "DejaVu Sans Mono";
        fontDefaultScale = 1;
        fontFixedScale = 1;
        tooltipsEnabled = true;
        panelBackgroundOpacity = 1;
        panelsAttachedToBar = true;
        settingsPanelAttachToBar = false;
      };

      # ===== 位置和天气 =====
      location = {
        name = "Marseille, France";
        monthBeforeDay = true;  // DD/MM/YYYY 格式
        weatherEnabled = true;
        weatherShowEffects = true;
        useFahrenheit = false;
        use12hourFormat = false;
        showWeekNumberInCalendar = false;
        showCalendarEvents = true;
        showCalendarWeather = true;
        analogClockInCalendar = false;
        firstDayOfWeek = -1;  // 自动
      };

      # ===== 通知 =====
      notifications = {
        enabled = true;
        location = "top_right";
        overlayLayer = true;
        backgroundOpacity = 1;
        respectExpireTimeout = false;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 8;
        criticalUrgencyDuration = 15;
        enableKeyboardLayoutToast = true;
      };

      # ===== 音频 =====
      audio = {
        volumeStep = 5;
        volumeOverdrive = false;
        cavaFrameRate = 30;
        visualizerType = "linear";
        visualizerQuality = "high";
        mprisBlacklist = [ ];
        preferredPlayer = "";
        externalMixer = "pwvucontrol || pavucontrol";
      };

      # ===== 亮度 =====
      brightness = {
        brightnessStep = 5;
        enforceMinimum = true;
        enableDdcSupport = false;
      };

      # ===== 主题配色 =====
      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Monochrome";
        darkMode = true;
        schedulingMode = "off";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        matugenSchemeType = "scheme-fruit-salad";
        generateTemplatesForPredefined = true;
      };

      # ===== 应用程序启动器 =====
      appLauncher = {
        enableClipboardHistory = false;
        enableClipPreview = true;
        position = "center";
        pinnedExecs = [ ];
        useApp2Unit = false;
        sortByMostUsed = true;
        terminalCommand = "xterm -e";
        customLaunchPrefixEnabled = false;
        customLaunchPrefix = "";
        viewMode = "list";
      };

      # ===== 系统监控 =====
      systemMonitor = {
        cpuWarningThreshold = 80;
        cpuCriticalThreshold = 90;
        tempWarningThreshold = 80;
        tempCriticalThreshold = 90;
        memWarningThreshold = 80;
        memCriticalThreshold = 90;
        diskWarningThreshold = 80;
        diskCriticalThreshold = 90;
        cpuPollingInterval = 3000;
        tempPollingInterval = 3000;
        memPollingInterval = 3000;
        diskPollingInterval = 3000;
        networkPollingInterval = 3000;
        useCustomColors = false;
        warningColor = "";
        criticalColor = "";
      };
    };

    # 主题颜色
    colors = {
      mError = "#dddddd";
      mOnError = "#111111";
      mOnPrimary = "#111111";
      mOnSecondary = "#111111";
      mOnSurface = "#828282";
      mOnSurfaceVariant = "#5d5d5d";
      mOnTertiary = "#111111";
      mOnHover = "#ffffff";
      mOutline = "#3c3c3c";
      mPrimary = "#aaaaaa";
      mSecondary = "#a7a7a7";
      mShadow = "#000000";
      mSurface = "#111111";
      mHover = "#1f1f1f";
      mSurfaceVariant = "#191919";
      mTertiary = "#cccccc";
    };

    # 可选：启用 systemd 服务
    # systemd.enable = true;
  };
}
```

### 9.2 配置选项详解

| 配置项 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `settingsVersion` | int | 25 | 配置文件版本号 |
| `bar.position` | enum | "top" | 条形栏位置：top, bottom, left, right |
| `bar.density` | enum | "default" | 条形栏密度：default, compact |
| `bar.showCapsule` | bool | true | 是否显示胶囊形状 |
| `location.name` | string | "Tokyo" | 默认城市名称 |
| `location.weatherEnabled` | bool | true | 是否启用天气功能 |
| `audio.volumeStep` | int | 5 | 音量调节步长（百分比） |
| `brightness.brightnessStep` | int | 5 | 亮度调节步长（百分比） |
| `colorSchemes.predefinedScheme` | string | "Noctalia (default)" | 预设配色方案 |

### 9.3 查看和比较配置

查看实际运行配置：

```bash
# 查看当前配置
jq . ~/.config/noctalia/settings.json

# 比较 Nix 配置与 GUI 设置
nix shell nixpkgs#jq nixpkgs#colordiff -c bash -c \
  "diff -u <(jq -S . ~/.config/noctalia/settings.json) <(jq -S . ~/.config/noctalia/gui-settings.json) | colordiff"

# 查看颜色配置
jq . ~/.config/noctalia/colors.json
```

### 9.4 配置导入导出

```bash
# 导出配置
cp ~/.config/noctalia/settings.json ~/noctalia-settings-backup.json

# 导入配置（需要重新启动）
cp ~/noctalia-settings-backup.json ~/.config/noctalia/settings.json
```

---

## 第十步：常见问题解决

### 10.1 系统依赖问题

**问题：WiFi/蓝牙/电池功能不工作**

解决方案：确保系统启用了必要的服务

```nix
# 检查并启用
networking.networkmanager.enable = true;
hardware.bluetooth.enable = true;
services.power-profiles-daemon.enable = true;
services.upower.enable = true;

# 重新构建
sudo nixos-rebuild switch
```

### 10.2 IPC 命令失败

**问题：快捷键触发 IPC 命令失败**

解决方案：
1. 检查 Noctalia 是否正在运行
2. 确保使用正确的命令格式
3. 如果使用 systemd 服务，在 home-manager 中设置 package 为 null

```nix
programs.noctalia-shell = {
  enable = true;
  package = null;  # 避免与 systemd 服务冲突
};
```

### 10.3 配置文件冲突

**问题：切换 Home Manager 代时出现备份文件冲突**

错误信息：
```
Existing file '/home/myuser/.config/noctalia/colors.json.backup'
would be clobbered by backing up '/home/myuser/.config/noctalia/colors.json'
```

解决方案：
```bash
# 删除备份文件
rm -rf ~/.config/noctalia/*.backup

# 重新切换配置
home-manager switch
```

### 10.4 主题不生效

**问题：自定义颜色主题不生效**

解决方案：
1. 确保设置了所有 Material 3 颜色
2. 检查颜色值格式（必须是 #RRGGBB）
3. 重新应用配置

```nix
# 完整示例：确保包含所有颜色
programs.noctalia-shell.colors = {
  # 错误状态
  mError = "#dddddd";
  mOnError = "#111111";

  # 主色
  mPrimary = "#aaaaaa";
  mOnPrimary = "#111111";

  # 次色
  mSecondary = "#a7a7a7";
  mOnSecondary = "#111111";

  # 表面
  mSurface = "#111111";
  mOnSurface = "#828282";
  mSurfaceVariant = "#191919";
  mOnSurfaceVariant = "#5d5d5d";

  # 三级色
  mTertiary = "#cccccc";
  mOnTertiary = "#111111";

  # 悬停
  mHover = "#1f1f1f";
  mOnHover = "#ffffff";

  # 边框和阴影
  mOutline = "#3c3c3c";
  mShadow = "#000000";
};
```

### 10.5 性能优化

**问题：Noctalia 消耗过多资源**

优化建议：
```nix
programs.noctalia-shell.settings = {
  # 降低更新频率
  systemMonitor = {
    cpuPollingInterval = 5000;   # 增加到 5 秒
    tempPollingInterval = 5000;
    memPollingInterval = 5000;
    diskPollingInterval = 10000;  # 磁盘更新更慢
    networkPollingInterval = 5000;
  };

  # 禁用不必要的动画
  general = {
    animationDisabled = true;
  };
};
```

### 10.6 日历功能问题

**问题：日历事件不显示**

解决方案：
1. 确认 Evolution Data Server 已启用
2. 检查 Python 绑定是否安装
3. 验证 GI_TYPELIB_PATH 环境变量

```bash
# 检查安装
python3 -c "import gi; print('OK')"

# 查看变量
echo $GI_TYPELIB_PATH

# 手动设置（临时）
export GI_TYPELIB_PATH=/run/current-system/sw/lib/girepository-1.0
```

---

## 第十一步：高级配置

### 11.1 自定义模板生成

Noctalia 可以为各种应用程序生成配色模板：

```nix
programs.noctalia-shell.settings.templates = {
  # GTK 应用程序
  gtk = true;

  # Qt 应用程序
  qt = true;

  # 终端模拟器
  alacritty = true;
  kitty = true;
  ghostty = true;
  foot = true;
  wezterm = true;

  # 代码编辑器
  code = true;      # VS Code
  emacs = true;

  # 应用程序
  discord = true;
  telegram = true;
  spicetify = true;
  fuzzel = true;

  # 其他工具
  cava = true;          # 音频可视化
  kcolorscheme = true;  # KDE 工具
  vicinae = true;
  walker = true;

  # 允许用户模板
  enableUserTemplates = true;
};
```

### 11.2 夜间模式调度

```nix
programs.noctalia-shell.settings = {
  # 夜间模式
  nightLight = {
    enabled = true;
    forced = false;
    autoSchedule = true;
    nightTemp = "4000";  # 夜间色温
    dayTemp = "6500";    # 日间色温
    manualSunrise = "06:30";
    manualSunset = "18:30";
  };

  # 自动配色方案
  colorSchemes = {
    schedulingMode = "system";  # 跟随系统
    # 或者使用 matugen
    # schedulingMode = "matugen";
    # matugenSchemeType = "scheme-vibrant";
  };
};
```

### 11.3 壁纸管理

```nix
programs.noctalia-shell.settings = {
  wallpaper = {
    enabled = true;
    directory = "/home/drfoobar/Pictures/Wallpapers";  # 壁纸目录
    recursiveSearch = true;  # 递归搜索
    setWallpaperOnAllMonitors = true;  # 所有显示器

    # 填充模式
    fillMode = "crop";  # crop, fit, stretch, center, tile, pad

    # 随机壁纸
    randomEnabled = true;
    randomIntervalSec = 300;  # 5 分钟切换

    # 过渡效果
    transitionDuration = 1500;  // 1.5 秒
    transitionType = "random";  // random, fade, slide, none
    transitionEdgeSmoothness = 0.05;

    # 使用 Wallhaven（可选）
    useWallhaven = false;
    wallhavenQuery = "nature";
    wallhavenSorting = "relevance";
    wallhavenOrder = "desc";
    wallhavenCategories = "111";  // 111 = 全部
    wallhavenPurity = "100";      // 100 = 仅 SFW
  };
};
```

### 11.4 屏幕录制配置

```nix
programs.noctalia-shell.settings = {
  screenRecorder = {
    directory = "~/Videos/Recordings";
    frameRate = 60;      // 帧率
    audioCodec = "opus"; // 音频编码：opus, aac, flac
    videoCodec = "h264"; // 视频编码：h264, h265, vp9
    quality = "very_high"; // very_low, low, medium, high, very_high

    // 视频源
    videoSource = "portal"; // portal, monitor

    // 音频源
    audioSource = "default_output"; // default_output, default_input, monitor
  };
};
```

### 11.5 媒体控制配置

```nix
programs.noctalia-shell.settings = {
  audio = {
    volumeStep = 5;
    volumeOverdrive = false;  // 允许超过 100%

    // 音频可视化
    cavaFrameRate = 30;
    visualizerType = "linear"; // linear, radial
    visualizerQuality = "high"; // low, medium, high

    // 媒体播放器
    mprisBlacklist = [ "spotify" ];  // 排除特定播放器
    preferredPlayer = "";            // 首选播放器名称

    // 外部混音器
    externalMixer = "pwvucontrol || pavucontrol || pulsemixer";
  };
};
```

### 11.6 通知配置

```nix
programs.noctalia-shell.settings = {
  notifications = {
    enabled = true;
    location = "top_right";
    overlayLayer = true;  // 覆盖层显示
    backgroundOpacity = 1;

    // 持续时间（秒）
    respectExpireTimeout = false;
    lowUrgencyDuration = 3;
    normalUrgencyDuration = 8;
    criticalUrgencyDuration = 15;

    // 键盘布局提示
    enableKeyboardLayoutToast = true;

    // 仅特定显示器
    monitors = [ ];  // 空 = 所有显示器
  };

  // OSD（屏幕显示）
  osd = {
    enabled = true;
    location = "top_right";
    autoHideMs = 2000;  // 2 秒后自动隐藏
    overlayLayer = true;
    backgroundOpacity = 1;

    // 启用类型
    enabledTypes = [
      0  // 音量
      1  // 亮度
      2  // 音量（输入）
    ];
  };
};
```

---

## 第十二步：开发和调试

### 12.1 启用调试模式

```nix
# 在环境变量中启用
environment.sessionVariables = {
  NOCTALIA_DEBUG = "1";
};

# 或在 systemd 服务中
services.noctalia-shell.environment = {
  NOCTALIA_DEBUG = "1";
};
```

### 12.2 查看日志

```bash
# 查看 systemd 日志
journalctl -f -u noctalia-shell

# 查看用户服务日志
journalctl --user -f -u noctalia-shell

# 搜索错误
journalctl -u noctalia-shell | grep -i error

# 查看最近的日志
journalctl -u noctalia-shell -n 50
```

### 12.3 验证配置

```bash
# 验证 JSON 语法
jq . ~/.config/noctalia/settings.json

# 验证 flake 配置
nix flake check

# 查看可用的配置选项
nix flake show github:noctalia-dev/noctalia-shell
```

### 12.4 更新

```bash
# 更新 flake 锁定
nix flake update

# 重新构建
sudo nixos-rebuild switch

# 更新 Home Manager
home-manager switch
```

---

## 总结

本教程详细介绍了在 NixOS 上安装、配置和使用 Noctalia 的全过程，包括：

1. **系统准备**：安装依赖项和启用必要服务
2. **安装过程**：通过 flake 添加和安装 Noctalia
3. **基础配置**：使用 Home Manager 管理配置
4. **主题定制**：Material 3 颜色主题和预设方案
5. **快捷键设置**：配置 compositor 快捷键
6. **运行方式**：手动运行、自启动和 systemd 服务
7. **功能扩展**：日历事件、壁纸管理等
8. **故障排除**：常见问题和解决方案
9. **高级配置**：自定义模板、夜间模式等
10. **调试和维护**：日志查看和配置验证

通过这个教程，您应该能够在 NixOS 系统上成功安装并个性化配置 Noctalia，享受现代化的桌面环境体验。

如需更多信息，请参考：
- [Noctalia 官方文档](https://docs.noctalia.dev)
- [NixOS 官方手册](https://nixos.org/manual/)
- [Home Manager 文档](https://nix-community.github.io/home-manager/)

祝您使用愉快！
