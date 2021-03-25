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
  tomcat-primary = rec {
    serverPort = 8005;
    httpPort = 8080;
    httpsPort = 8443;
    ajpPort = 8009;

    pkg = constructors.simpleAppservingTomcat {
      inherit serverPort httpPort httpsPort ajpPort;
      instanceSuffix = "-primary";
    };
  };

  tomcat-secondary = rec {
    serverPort = 8006;
    httpPort = 8081;
    httpsPort = 8444;
    ajpPort = 8010;

    pkg = constructors.simpleAppservingTomcat {
      inherit serverPort httpPort httpsPort ajpPort;
      instanceSuffix = "-secondary";
    };
  };
}
