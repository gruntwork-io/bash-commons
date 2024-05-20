{
  description = "bash-commons via nix flakes";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = inputs @ {
    flake-parts,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        formatter = pkgs.alejandra;
        packages.default = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "bash-commons";
          version = builtins.toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
          src = ./modules/bash-commons/src;
          phases = ["installPhase" "fixupPhase"];
          installPhase = ''
            mkdir -p $out/bin
            cp $src/array.sh $out/bin/array.sh
            cp $src/assert.sh $out/bin/assert.sh
            cp $src/file.sh $out/bin/file.sh
            cp $src/log.sh $out/bin/log.sh
            cp $src/string.sh $out/bin/string.sh
            cp $src/string.sh $out/bin/os.sh

            chmod +x $out/bin/array.sh
            chmod +x $out/bin/assert.sh
            chmod +x $out/bin/file.sh
            chmod +x $out/bin/log.sh
            chmod +x $out/bin/string.sh
            chmod +x $out/bin/os.sh
          '';

          doCheck = false;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [self'.packages.default];
        };
      };
    };
}
