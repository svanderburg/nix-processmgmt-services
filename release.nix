{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
, nix-processmgmt ? { outPath = ../nix-processmgmt; rev = 1234; }
, processManagers ? [ "supervisord" "sysvinit" "systemd" "disnix" "s6-rc" ]
, profiles ? [ "privileged" "unprivileged" ]
}:

let
  pkgs = import nixpkgs {};
in
{
  tests = import ./tests {
    inherit nixpkgs system nix-processmgmt processManagers profiles;
  };
}
