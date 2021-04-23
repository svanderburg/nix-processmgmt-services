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
  tomcat = rec {
    ajpPort = 8009;
    httpPort = 8080;

    pkg = constructors.simpleAppservingTomcat {
      enableAJP = true;
      inherit ajpPort httpPort;
    };
  };

  apache = rec {
    port = if forceDisableUserChange then 8081 else 80;

    pkg = constructors.reverseProxyApache {
      inherit port;
      dependency = tomcat;
      serverAdmin = "admin@localhost";
      targetProtocol = "ajp";
      portPropertyName = "ajpPort";
    };
  };
}
