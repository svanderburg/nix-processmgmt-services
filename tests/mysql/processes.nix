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
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager nix-processmgmt;
  };
in
rec {
  mysql = rec {
    port = 3306;
    instanceSuffix = "";

    pkg = constructors.mysql {
      inherit port instanceSuffix;
    };
  };

  mysql-secondary = rec {
    port = 3307;
    instanceSuffix = "-secondary";

    pkg = constructors.mysql {
      inherit port instanceSuffix;
    };
  };
}
