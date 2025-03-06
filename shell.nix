{ pkgs, libraries, ... }:

{
  extraPackages ? [],
  extraLibraries ? [],
  extraArgs ? {},
}:

 pkgs.mkShell (extraArgs // {
   NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (libraries ++ extraLibraries);
   UV_PYTHON_PREFERENCE = "only-managed";
   HATCH_ENV_TYPE_VIRTUAL_UV_PATH = "${pkgs.uv}/bin/uv";

   packages = [ pkgs.uv ] ++ extraPackages;
 })
