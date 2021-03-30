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
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange processManager;
  };
in
rec {
  supervisord-primary = rec {
    # Special situation: we can only bootstrap supervisord with supervisord if we don't conflict with the managing supervisord's port
    port = if processManager == "supervisord" then 9003 else 9001;

    pkg = constructors.extendableSupervisord {
      inetHTTPServerPort = port;
      instanceSuffix = "-primary";
    };
  };

  supervisord-secondary = rec {
    port = 9002;

    pkg = constructors.extendableSupervisord {
      inetHTTPServerPort = port;
      instanceSuffix = "-secondary";
    };
  };
}
