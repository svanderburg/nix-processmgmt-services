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
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir forceDisableUserChange processManager;
  };

  containerProviderConstructors = import ../../service-containers-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir forceDisableUserChange processManager;
  };
in
rec {
  sshd = {
    pkg = constructors.sshd {
      extraSSHDConfig = ''
        UsePAM yes
      '';
    };
  };

  dbus-daemon = {
    pkg = constructors.dbus-daemon {
      services = [ disnix-service ];
    };
  };

  tomcat-primary = containerProviderConstructors.disnixAppservingTomcat {
    instanceSuffix = "-primary";
    httpPort = 8080;
    httpsPort = 8443;
    serverPort = 8005;
    ajpPort = 8009;
    commonLibs = [ "${pkgs.mysql_jdbc}/share/java/mysql-connector-java.jar" ];
    webapps = [
      pkgs.tomcat9.webapps # Include the Tomcat example and management applications
    ];
  };

  tomcat-secondary = containerProviderConstructors.disnixAppservingTomcat {
    instanceSuffix = "-secondary";
    httpPort = 8081;
    httpsPort = 8444;
    serverPort = 8006;
    ajpPort = 8010;
    commonLibs = [ "${pkgs.mysql_jdbc}/share/java/mysql-connector-java.jar" ];
    webapps = [
      pkgs.tomcat9.webapps # Include the Tomcat example and management applications
    ];
  };

  mysql-primary = containerProviderConstructors.mysql {
    instanceSuffix = "-primary";
    port = 3306;
  };

  mysql-secondary = containerProviderConstructors.mysql {
    instanceSuffix = "-secondary";
    port = 3307;
  };

  disnix-service = {
    pkg = constructors.disnix-service {
      inherit dbus-daemon;
      containerProviders = [ tomcat-primary tomcat-secondary mysql-primary mysql-secondary ];
      authorizedUsers = [ tomcat-primary.name tomcat-secondary.name ];
    };
  };
}
