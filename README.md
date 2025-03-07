# manylinux on NixOS

By utilizing [nix-ld](https://github.com/nix-community/nix-ld),
we provide [manylinux](https://github.com/pypa/manylinux) compatible environment
on [NixOS](https://nixos.org/).


So that you can run pre-compiled wheel binaries hosted at [PyPI](https://pypi.org/) etc.


## Prerequisite

nix-ld enabled NixOS.

Minimal configuration is following;


```nix
{
  programs.nix-ld = {
    enable = true;
    libraries = [];
  };
}
```


## Usage

Simple manylinux development shell can start by following command;

```shell
nix --experimental-features "nix-command flakes" develop -L github:ymd-h/manylinux-nixos
```

[uv](https://docs.astral.sh/uv/) is installed,
so that you can install and run python packages with uv.


Environment variable `HATCH_ENV_TYPE_VIRTUAL_UV_PATH` is configured,
so that you can use [hatch](https://hatch.pypa.io/) with uv installer
by `uvx hatch ...`.
This is useful if your project has multiple virtual environments.


> [!WARNING]
> You cannot mix with Nix-managed Python ecosystem.



## Advanced Usage

Custom make shell function is defined as `lib.${system}.manylinux2014.mkShell attr`.
Argument `attr` can take optional attributes
`extraPackages` (list), `extraLibraries` (list), and `extraArgs` (any),
which will be passed to `pkgs.stdenv.mkShell`.

An example `flake.nix` is following;

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    manylinux = {
      url = "github:ymd-h/manylinux-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, manylinux, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = manylinux.lib.${system};
  in
  {
    devShells.${system}.default = lb.manylinux2014.mkShell {
      extraPackages = [ pkgs.actionlint ];
    };
  };
}
```


## Pros & Cons


- Pros
  - Widely available prebuild manylinux wheels can be used without any patches
  - Ordinary package manager like uv can be used.
    - We recommend to use uv since uv itself isn't written by Python.
- Cons
  - No Nix-based reproducibility
    - This can be mitigated by using [uv's lock mechanism](https://docs.astral.sh/uv/concepts/projects/sync/)
