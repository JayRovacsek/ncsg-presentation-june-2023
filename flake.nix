{
  description = "NCSG Presentation";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    gitignore.url = "github:hercules-ci/gitignore.nix";

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

  outputs = { self, flake-utils, gitignore, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (gitignore.lib) gitignoreSource;
      in {
        checks.pre-commit = self.inputs.pre-commit-hooks.lib.${system}.run {
          src = gitignoreSource ./.;
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
          packages = (with pkgs; [ deadnix go hugo nixfmt statix typos ])
            ++ nodePackages;
        in {
          default = self.devShells.${system}.${name};
          "${name}" = pkgs.mkShell {
            inherit name packages;
            inherit (self.checks.${system}.pre-commit) shellHook;
          };
        };
      });
}
