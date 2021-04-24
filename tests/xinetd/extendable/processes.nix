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
, callingUser ? null
, processManager
, nix-processmgmt ? ../../../../nix-processmgmt
}:

let
  constructors = import ../../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange callingUser processManager nix-processmgmt;
  };
in
rec {
  xinetd-primary = {
    port = if forceDisableUserChange then 6969 else 69;

    pkg = constructors.extendableXinetd {
      instanceSuffix = "-primary";
    };
  };

  xinetd-secondary = {
    port = if forceDisableUserChange then 2323 else 23;

    pkg = constructors.extendableXinetd {
      instanceSuffix = "-secondary";
    };
  };
}
