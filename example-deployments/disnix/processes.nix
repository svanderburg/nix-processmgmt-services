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
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir forceDisableUserChange processManager;
  };
in
rec {
  openssh = rec {
    pkg = constructors.openssh {
      extraSSHDConfig = ''
        UsePAM yes
      '';
    };
  };

  dbus-daemon = {
    pkg = constructors.dbus-daemon {
      packages = [ pkgs.disnix ];
    };
  };

  disnix-service = {
    pkg = constructors.disnix-service {
      inherit dbus-daemon;
    };
  };
}
