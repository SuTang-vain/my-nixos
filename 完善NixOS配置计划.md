# NixOS 配置完善计划：集成 Noctalia

您好！根据您现有的 `configuration.nix` 以及您提供的 `NixOS-中文详细教程.md`，我为您制定了一个阶段性的计划，旨在将您的系统平稳地过渡到基于 Flake 和 Home Manager 的现代化管理方式，并成功集成 Noctalia 桌面 Shell。

## 核心思路

当前配置是单个 `configuration.nix` 文件，而教程推荐使用 Flakes 和 Home Manager 进行模块化管理。因此，我们的首要任务是改造基础架构，然后再引入新功能。

---

## 第一阶段：迁移到 Flakes 管理

Flakes 是现代 NixOS 管理的核心，能提供更可复现、更可靠的系统配置。这是集成 Noctalia 的前提。

**目标**：将现有配置转化为 Flake 结构，为后续步骤打下基础。

**步骤**：

1.  **创建 `flake.nix` 文件**:
    在您的项目根目录 (`/home/sutang-vain/01_sutang-vain/02_Project/NixOS/`) 创建 `flake.nix` 文件。此文件将成为您系统配置的入口。

    ```nix
    # flake.nix
    {
      description = "sutang's NixOS configuration";

      inputs = {
        # 使用教程推荐的 nixpkgs 不稳定分支
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      };

      outputs = { self, nixpkgs, ... }@inputs: {
        nixosConfigurations = {
          # 主机名 "nixos" 来自您现有的 configuration.nix
          nixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; }; # 将 inputs 传入模块
            modules = [
              # 导入您现有的配置文件
              ./configuration.nix
            ];
          };
        };
      };
    }
    ```

2.  **验证和应用 Flake 配置**:
    运行以下命令，将系统切换到由 Flake 管理。这不会改变您现有的任何功能，只是改变了配置的加载方式。

    ```bash
    # 第一次构建，请确保没有语法错误
    sudo nixos-rebuild switch --flake .
    ```

---

## 第二阶段：引入 Home Manager

Home Manager 用于管理用户级别的配置（“dotfiles”），是配置 Noctalia 的关键工具。

**目标**：集成 Home Manager，实现用户环境的声明式管理。

**步骤**：

1.  **更新 `flake.nix` 以添加 Home Manager**:

    ```nix
    # flake.nix (更新后)
    {
      description = "sutang's NixOS configuration";

      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        # 添加 home-manager 输入
        home-manager = {
          url = "github:nix-community/home-manager";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };

      outputs = { self, nixpkgs, home-manager, ... }@inputs: {
        nixosConfigurations = {
          nixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              # 启用 home-manager 的 NixOS 模块
              home-manager.nixosModules.default
              
              ./configuration.nix

              # 为用户 'sutang' 引入 Home Manager 配置
              ./home.nix
            ];
          };
        };
      };
    }
    ```

2.  **创建 `home.nix` 文件**:
    此文件将专门管理用户 `sutang` 的个人配置。

    ```nix
    # home.nix
    { config, pkgs, ... }:

    {
      # 为用户 'sutang' 启用 Home Manager
      home-manager.users.sutang = {
        home.stateVersion = "25.05"; # 与 system.stateVersion 保持一致

        # 将原本在 configuration.nix 中的用户软件包移到这里
        home.packages = with pkgs; [
          kdePackages.kate
        ];

        # 基本配置
        home.username = "sutang";
        home.homeDirectory = "/home/sutang";
      };
    }
    ```

3.  **清理 `configuration.nix`**:
    从 `configuration.nix` 中删除 `users.users.sutang.packages` 部分，因为它现在由 `home.nix` 管理。

4.  **应用 Home Manager 配置**:
    再次运行构建命令以应用更改。

    ```bash
    sudo nixos-rebuild switch --flake .
    ```

---

## 第三阶段：安装和基础配置 Noctalia

现在，基础架构已经准备就绪，我们可以开始安装 Noctalia。

**重要提示**：Noctalia 是一个独立的桌面 Shell，通常搭配 Niri 或 Hyprland 等窗口合成器使用，而不是在 Plasma 6 内部运行。因此，本计划将为您安装 `Niri` 作为运行 Noctalia 的环境。您可以在登录时选择进入 Niri 会话或您原来的 Plasma 会话。

**目标**：安装 Noctalia 和 Niri，并完成初步配置。

**步骤**：

1.  **更新 `flake.nix` 以添加 Noctalia**:

    ```nix
    # flake.nix (更新后)
    {
      # ... inputs ...
      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        home-manager = {
          url = "github:nix-community/home-manager";
          inputs.nixpkgs.follows = "nixpkgs";
        };
        # 添加 noctalia 输入
        noctalia = {
          url = "github:noctalia-dev/noctalia-shell";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
      # ... outputs ...
    }
    ```

2.  **在 `configuration.nix` 中添加系统依赖**:
    根据教程，确保以下服务已启用。`networking.networkmanager` 已存在，只需补充其余部分。

    ```nix
    # 在 configuration.nix 中
    services.upower.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    
    # 同时安装 Niri 合成器
    programs.niri.enable = true;
    ```

3.  **在 `home.nix` 中安装和配置 Noctalia**:
    将 Noctalia 的包和配置添加到 `home.nix` 中。

    ```nix
    # home.nix (更新后)
    { config, pkgs, inputs, ... }: # 注意添加 inputs

    {
      home-manager.users.sutang = {
        # ... 其他 home-manager 配置 ...
        
        # 导入 Noctalia 的 Home Manager 模块
        imports = [
          inputs.noctalia.homeModules.default
        ];

        # 安装 Noctalia 包
        home.packages = with pkgs; [
          kdePackages.kate
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        
        # 启用并配置 Noctalia
        programs.noctalia-shell = {
          enable = true;
          settings = {
            settingsVersion = 25;
            bar.position = "top";
            # ... 此处可以根据教程添加更多基础配置 ...
          };
        };

        # 配置 Niri，使其在启动时运行 Noctalia
        programs.niri.settings = {
          "spawn-at-startup" = [
            { command = [ "noctalia-shell" ]; }
          ];
        };
      };
    }
    ```

4.  **应用最终配置**:

    ```bash
    sudo nixos-rebuild switch --flake .
    ```

---

## 第四阶段：后续完善与定制

完成以上阶段后，您就有了一个可以运行 Noctalia 的基本环境。您可以注销当前会话，在登录管理器 (SDDM) 中选择 `Niri` 会话登录。

**后续步骤建议**：

1.  **主题与颜色**：在 `home.nix` 的 `programs.noctalia-shell` 部分，根据教程添加 `colors` 或 `colorSchemes` 配置来美化您的界面。
2.  **快捷键绑定**：在 `home.nix` 的 `programs.niri.settings` 部分，根据教程第六步，为您常用的 Noctalia 功能（如启动器、锁屏）绑定快捷键。
3.  **功能扩展**：尝试启用日历 (`services.gnome.evolution-data-server.enable`)、壁纸管理等高级功能。
4.  **模块化配置**：为了保持整洁，您可以将 Noctalia 相关的配置（如 `programs.noctalia-shell` 和 `programs.niri`）拆分到一个单独的 `noctalia.nix` 文件中，然后在 `home.nix` 中导入它。

这个计划为您提供了一条清晰的路径。祝您配置顺利！
