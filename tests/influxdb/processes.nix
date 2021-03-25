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
  influxdb = rec {
    rpcPort = 8088;
    httpPort = 8086;

    pkg = constructors.simpleInfluxdb {
      inherit rpcPort httpPort;
    };
  };

  influxdb-secondary = rec {
    rpcPort = 8092;
    httpPort = 8090;

    pkg = constructors.simpleInfluxdb {
      inherit rpcPort httpPort;
      instanceSuffix = "-secondary";
    };
  };
}
