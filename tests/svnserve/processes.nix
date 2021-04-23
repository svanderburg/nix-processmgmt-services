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
  svnserve = rec {
    port = 3690;
    svnBaseDir = "${stateDir}/repos";

    pkg = constructors.svnserve {
      inherit port svnBaseDir;
      svnGroup = "root";
    };
  };

  svnserve-secondary = rec {
    port = 3691;
    svnBaseDir = "${stateDir}/repos-secondary";

    pkg = constructors.svnserve {
      inherit port svnBaseDir;
      instanceSuffix = "-secondary";
      svnGroup = "root";
    };
  };
}
