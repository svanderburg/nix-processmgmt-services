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
  sshd = rec {
    port = if forceDisableUserChange then 2222 else 22;
    instanceSuffix = "";

    pkg = constructors.sshd {
      inherit port instanceSuffix;
    };
  };

  sshd-secondary = rec {
    port = if forceDisableUserChange then 2223 else 23;
    instanceSuffix = "-secondary";

    pkg = constructors.sshd {
      inherit port instanceSuffix;
    };
  };
}
