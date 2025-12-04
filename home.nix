{ config, pkgs, inputs, ... }: # Add inputs

{
  # 为用户 'sutang' 启用 Home Manager
  home-manager.users.sutang = {
    imports = [
      # Import Noctalia's Home Manager module
      inputs.noctalia.homeModules.default
    ];

    home.stateVersion = "25.05"; # 与 system.stateVersion 保持一致

    # 将原本在 configuration.nix 中的用户软件包移到这里
    home.packages = with pkgs; [
      kdePackages.kate
      # Add Noctalia package
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # 基本配置
    home.username = "sutang";
    home.homeDirectory = "/home/sutang";

    # Enable and configure Noctalia
    programs.noctalia-shell = {
      enable = true;
      settings = {
        settingsVersion = 25;
        bar.position = "top";
        # ... more basic settings can be added here from the tutorial ...
      };
    };

    # Configure Niri to start Noctalia on launch
    programs.niri.settings = {
      "spawn-at-startup" = [
        { command = [ "noctalia-shell" ]; }
      ];
    };
  };
}
