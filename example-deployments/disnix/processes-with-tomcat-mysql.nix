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
, enablePAM ? false
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  ids = if builtins.pathExists ./ids-tomcat-mysql.nix then (import ./ids-tomcat-mysql.nix).ids else {};

  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager ids nix-processmgmt;
  };

  containerProviderConstructors = import ../../service-containers-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir forceDisableUserChange processManager ids nix-processmgmt;
  };
in
rec {
  sshd = rec {
    port = 22;

    pkg = constructors.sshd {
      inherit port;

      extraSSHDConfig = pkgs.lib.optionalString enablePAM ''
        UsePAM yes
      '';
    };

    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  dbus-daemon = {
    pkg = constructors.dbus-daemon {
      services = [ disnix-service ];
    };

    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  tomcat = containerProviderConstructors.disnixAppservingTomcat {
    commonLibs = [ "${pkgs.mysql_jdbc}/share/java/mysql-connector-java.jar" ];
    webapps = [
      pkgs.tomcat9.webapps # Include the Tomcat example and management applications
    ];
    enableAJP = true;
    inherit dbus-daemon;

    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  apache = rec {
    port = 80;

    pkg = constructors.basicAuthReverseProxyApache {
      inherit port;

      dependency = tomcat;
      serverAdmin = "admin@localhost";
      targetProtocol = "ajp";
      portPropertyName = "ajpPort";

      authName = "DisnixWebService";
      authUserFile = pkgs.stdenv.mkDerivation {
        name = "htpasswd";
        buildInputs = [ pkgs.apacheHttpd ];
        buildCommand = ''
          htpasswd -cb ./htpasswd admin secret
          mv htpasswd $out
        '';
      };
      requireUser = "admin";
    };

    requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  mysql = containerProviderConstructors.mysql {
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  disnix-service = {
    pkg = constructors.disnix-service {
      inherit dbus-daemon;
      containerProviders = [ tomcat mysql ];
      authorizedUsers = [ tomcat.name ];
      dysnomiaProperties = {
        targetEPR = "http://$(hostname)/DisnixWebService/services/DisnixWebService";
      };
    };

    requiresUniqueIdsFor = [ "gids" ];
  };
}
