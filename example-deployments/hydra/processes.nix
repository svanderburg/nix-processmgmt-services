{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, cacheDir ? "${stateDir}/cache"
, spoolDir ? "${stateDir}/spool"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
, includeNixDaemon ? false
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager;
  };

  instanceSuffix = "";
  hydraUser = hydraInstanceName;
  hydraInstanceName = "hydra${instanceSuffix}";
  hydraQueueRunnerUser = "hydra-queue-runner${instanceSuffix}";
  hydraServerUser = "hydra-www${instanceSuffix}";

  # This process needs to be conditionally included
  nix-daemon = if includeNixDaemon then {
    pkg = constructors.nix-daemon;
  } else null;
in
pkgs.lib.optionalAttrs includeNixDaemon {
  inherit nix-daemon;
} // rec {
  postgresql = rec {
    port = 5432;
    postgresqlUsername = "postgresql";
    postgresqlPassword = "postgresql";
    socketFile = "${runtimeDir}/postgresql/.s.PGSQL.${toString port}";

    pkg = constructors.simplePostgresql {
      inherit port;
      authentication = ''
        # TYPE  DATABASE   USER   ADDRESS    METHOD
        local   hydra      all               ident map=hydra-users
      '';
      identMap = ''
        # MAPNAME       SYSTEM-USERNAME          PG-USERNAME
        hydra-users     ${hydraUser}             ${hydraUser}
        hydra-users     ${hydraQueueRunnerUser}  ${hydraUser}
        hydra-users     ${hydraServerUser}       ${hydraUser}
        hydra-users     root                     ${hydraUser}
        # The postgres user is used to create the pg_trgm extension for the hydra database
        hydra-users     postgresql               postgresql
      '';
    };
  };

  hydra-server = rec {
    port = 3000;
    hydraDatabase = hydraInstanceName;
    hydraGroup = hydraInstanceName;
    baseDir = "${libDir}/${hydraInstanceName}";
    inherit hydraUser instanceSuffix;

    pkg = constructors.hydra-server {
      postgresqlDBMS = postgresql;
      user = hydraServerUser;
      inherit nix-daemon port instanceSuffix hydraInstanceName hydraDatabase hydraUser hydraGroup baseDir;
    };
  };

  hydra-evaluator = {
    pkg = constructors.hydra-evaluator {
      inherit nix-daemon hydra-server;
      postgresqlDBMS = postgresql;
    };
  };

  hydra-queue-runner = {
    pkg = constructors.hydra-queue-runner {
      inherit nix-daemon hydra-server;
      user = hydraQueueRunnerUser;
      postgresqlDBMS = postgresql;
    };
  };

  apache = rec {
    port = 80;
    pkg = constructors.reverseProxyApache {
      inherit port;
      dependency = hydra-server;
      serverAdmin = "admin@localhost";
    };
  };
}
