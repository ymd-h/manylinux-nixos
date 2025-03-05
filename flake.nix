{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ...}:
  flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      libso = {
        # See: https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/interpreters/python/manylinux/default.nix
        manylinux2014 = with pkgs; [
          glibc
          stdenv.cc.cc
          xorg.libX11
          xorg.libXext
          xorg.libXrender
          xorg.libICE
          xorg.libSM
          libGL
          glib
          zlib
          expat
        ];
      };

      # Ref: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/ldso.nix
      libDir = pkgs.stdenv.hostPlatform.libDir;
      ldsoBasename = builtins.unsafeDiscardStringContext (
        pkgs.lib.last (pkgs.lib.splitString "/" pkgs.stdenv.cc.bintools.dynamicLinker)
      );
      ldso = "${pkgs.nix-ld}/libexec/nix-ld";

      nix-ld-libraries = libraries: pkgs.buildEnv {
        name = "ld-library-path";
        pathsToLink = ["/lib"];
        paths = builtins.map pkgs.lib.getLib libraries;

        extraPrefix = "/share/nix-ld";
        ignoreCollisions = true;
      };

    in rec {
      lib = pkgs.lib.attrsets.mapAttrs
        (name: libraries: {
          libraries = libraries;

          mkShell = import ./shell.nix { inherit pkgs libraries; };
        })
        libso;

      devShells = (
        pkgs.lib.attrsets.mapAttrs
          (name: libraries: lib.${name}.mkShell {})
          libso
      ) // {
        # For nixos/nix container: https://hub.docker.com/r/nixos/nix
        test = lib.manylinux2014.mkShell {
          extraPackages = [
            (nix-ld-libraries libso.manylinux2014)
            pkgs.nix-ld
          ];
          extraArgs = {
            NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;

            shellHook = ''
              mkdir -p /${libDir}
              ln -s ${ldso} /${libDir}/${ldsoBasename}
            '';
          };
        };
      };
    }
  );
}
