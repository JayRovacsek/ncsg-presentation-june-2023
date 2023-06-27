{
  description = "NCSG Presentation";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    gitignore.url = "github:hercules-ci/gitignore.nix";

    microvm = {
      url = "github:astro/microvm.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixOS/nixpkgs/nixpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
      };
    };
  };

  outputs = { self, flake-utils, gitignore, nixpkgs, microvm, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs.lib) mapAttrs;
        inherit (gitignore.lib) gitignoreSource;
        inherit (self.lib.${system}) nixosToApp;
      in {
        apps = {
          build = {
            type = "app";
            program = builtins.toString (pkgs.writers.writeBash "build" ''
              ${pkgs.hugo}/bin/hugo -s .
            '');
          };
          develop = {
            type = "app";
            program = builtins.toString (pkgs.writers.writeBash "develop" ''
              ${pkgs.hugo}/bin/hugo server
            '');
          };
        } // mapAttrs (_: value: nixosToApp value.config)
          self.nixosConfigurations;

        checks.pre-commit = self.inputs.pre-commit-hooks.lib.${system}.run {
          src = gitignoreSource self;
          hooks = {
            # Builtin hooks
            deadnix.enable = true;
            nixfmt.enable = true;
            prettier.enable = true;
            statix.enable = true;
            typos.enable = true;

            # Custom hooks
            statix-write = {
              enable = true;
              name = "Statix Write";
              entry = "${pkgs.statix}/bin/statix fix";
              language = "system";
              pass_filenames = false;
            };
          };

          # Settings for builtin hooks, see also: https://github.com/cachix/pre-commit-hooks.nix/blob/master/modules/hooks.nix
          settings = {
            deadnix.edit = true;
            nixfmt.width = 80;
            prettier.write = true;
          };
        };

        devShells = let
          name = "hugo-revealjs";
          nodePackages = with pkgs.nodePackages; [ eslint prettier ];
          packages =
            (with pkgs; [ deadnix go hugo nixfmt statix typos trivy vulnix ])
            ++ nodePackages;
        in {
          default = self.devShells.${system}.${name};
          "${name}" = pkgs.mkShell {
            inherit name packages;
            inherit (self.checks.${system}.pre-commit) shellHook;
          };
        };

        lib.nixosToApp = config: {
          type = "app";
          program = "${config.microvm.declaredRunner}/bin/microvm-run";
        };

        packages = import ./packages { inherit self system; };
      }) // {
        nixosConfigurations = import ./microvms { inherit self; };
      };
}
