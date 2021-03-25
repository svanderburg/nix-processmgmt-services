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
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager;
  };
in
rec {
  mongodb = rec {
    port = 27017;

    pkg = constructors.simpleMongodb {
      inherit port;
    };
  };

  mongodb-secondary = rec {
    port = 27018;

    pkg = constructors.simpleMongodb {
      inherit port;
      instanceSuffix = "-secondary";
    };
  };
}
