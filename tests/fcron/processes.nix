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
, callingGroup ? null
, processManager
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange callingUser callingGroup processManager nix-processmgmt;
  };
in
rec {
  fcron = {
    pkg = constructors.declarativeFcron {
      fcrontabPerUser = {
        systab = ''
          */1 * * * * echo hello >> /tmp/hello
        '';
      };
    };
  };

  fcron-secondary = {
    pkg = constructors.declarativeFcron {
      instanceSuffix = "-secondary";
      fcrontabPerUser = {
        systab = ''
          */1 * * * * echo bye >> /tmp/bye
        '';
      };
    };
  };
}
