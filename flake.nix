{
  description = "bash-commons via nix flakes";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          formatter = pkgs.nixfmt-rfc-style;
          packages = {
            default =
              # if not darwin system then regex an
              let
                filter = if pkgs.stdenv.isLinux then '''' else ''| grep --invert -E "os|ubuntu" '';
              in
              # no need for c(pp) compiler
              pkgs.stdenvNoCC.mkDerivation rec {
                pname = "bash-commons";
                version = builtins.toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
                src = ./modules/bash-commons/src;
                phases = [
                  "installPhase"
                  "fixupPhase"
                ];
                installPhase = ''
                  mkdir -p $out/bin
                  find $src -type f ${filter} | xargs -I{} cp {} $out/bin/
                  chmod +x $out/bin/*.sh
                '';
                doCheck = false;
              };

            # run this to make universal check
            check = pkgs.writeScriptBin "check" ''
              nix flake check --print-build-logs --show-trace --no-build --debug --verbose --all-systems
              nix build
            '';
          };
          devShells.default = pkgs.mkShell { buildInputs = [ self'.packages.default ]; };
        };
    };
}
