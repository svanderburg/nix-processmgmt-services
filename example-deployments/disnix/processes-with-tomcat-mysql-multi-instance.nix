{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, spoolDir ? "${stateDir}/spool"
, cacheDir ? "${stateDir}/cache"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  ids = if builtins.pathExists ./ids-tomcat-mysql-multi-instance.nix then (import ./ids-tomcat-mysql-multi-instance.nix).ids else {};

  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir forceDisableUserChange processManager ids;
  };

  containerProviderConstructors = import ../../service-containers-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir forceDisableUserChange processManager ids;
  };
in
rec {
  sshd = {
    pkg = constructors.sshd {
      extraSSHDConfig = ''
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

  tomcat-primary = containerProviderConstructors.simpleAppservingTomcat {
    instanceSuffix = "-primary";
    httpPort = 8080;
    httpsPort = 8443;
    serverPort = 8005;
    ajpPort = 8009;
    commonLibs = [ "${pkgs.mysql_jdbc}/share/java/mysql-connector-java.jar" ];
    webapps = [
      pkgs.tomcat9.webapps # Include the Tomcat example and management applications
    ];
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  tomcat-secondary = containerProviderConstructors.simpleAppservingTomcat {
    instanceSuffix = "-secondary";
    httpPort = 8081;
    httpsPort = 8444;
    serverPort = 8006;
    ajpPort = 8010;
    commonLibs = [ "${pkgs.mysql_jdbc}/share/java/mysql-connector-java.jar" ];
    webapps = [
      pkgs.tomcat9.webapps # Include the Tomcat example and management applications
    ];
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  mysql-primary = containerProviderConstructors.mysql {
    instanceSuffix = "-primary";
    port = 3306;
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  mysql-secondary = containerProviderConstructors.mysql {
    instanceSuffix = "-secondary";
    port = 3307;
    properties.requiresUniqueIdsFor = [ "uids" "gids" ];
  };

  disnix-service = {
    pkg = constructors.disnix-service {
      inherit dbus-daemon;
      containerProviders = [ tomcat-primary tomcat-secondary mysql-primary mysql-secondary ];
    };

    requiresUniqueIdsFor = [ "gids" ];
  };
}
