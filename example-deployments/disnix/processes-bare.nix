{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, spoolDir ? "${stateDir}/spool"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  ids = if builtins.pathExists ./ids-bare.nix then (import ./ids-bare.nix).ids else {};

  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir forceDisableUserChange processManager ids;
  };
in
rec {
  sshd = {
    pkg = constructors.sshd {
      extraSSHDConfig = ''
        UsePAM yes
      '';
    };

    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  dbus-daemon = {
    pkg = constructors.dbus-daemon {
      services = [ disnix-service ];
    };

    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  disnix-service = {
    pkg = constructors.disnix-service {
      inherit dbus-daemon;
    };

    requiresUniqueIdsFor = [ "gids" ];
  };
}
