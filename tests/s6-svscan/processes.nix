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
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange processManager nix-processmgmt;
  };
in
rec {
  s6-svscan-primary = rec {
    instanceSuffix = "-primary";
    pkg = constructors.s6-svscan {
      inherit instanceSuffix;
    };
  };

  s6-svscan-secondary = rec {
    instanceSuffix = "-secondary";
    pkg = constructors.s6-svscan {
      inherit instanceSuffix;
    };
  };
}
