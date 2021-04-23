{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, spoolDir ? "${stateDir}/spool"
, cacheDir ? "${stateDir}/cache"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
, enablePAM ? false
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  ids = if builtins.pathExists ./ids-apache-mysql.nix then (import ./ids-apache-mysql.nix).ids else {};

  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager ids nix-processmgmt;
  };

  containerProviderConstructors = import ../../service-containers-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager ids nix-processmgmt;
  };
in
rec {
  sshd = rec {
    port = 22;

    pkg = constructors.sshd {
      inherit port;

      extraSSHDConfig = pkgs.lib.optionalString enablePAM ''
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

  apache = containerProviderConstructors.simpleWebappApache {
    serverAdmin = "root@localhost";
    documentRoot = "/var/www";
    enablePHP = true;
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  mysql = containerProviderConstructors.mysql {
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  disnix-service = {
    pkg = constructors.disnix-service {
      inherit dbus-daemon;
      containerProviders = [ apache mysql ];
    };

    requiresUniqueIdsFor = [ "gids" ];
  };
}
