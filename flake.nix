{
      description = "sutang's NixOS configuration";

      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        # 添加 home-manager 输入
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
