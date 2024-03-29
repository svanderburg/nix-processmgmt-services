{ nix-processmgmt ? ../../nix-processmgmt
, pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, spoolDir
, libDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
}:

let
  constructors = import ../services-agnostic/constructors.nix {
    inherit nix-processmgmt pkgs stateDir logDir runtimeDir cacheDir spoolDir libDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  simpleWebappApache = import ./apache/simple-webapp-apache.nix {
    apacheConstructorFun = constructors.simpleWebappApache;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableApacheWebApplication = true;
    });
    inherit forceDisableUserChange;
    inherit (pkgs) lib;
  };

  simpleAppservingTomcat = import ./apache-tomcat/simple-appserving-tomcat.nix {
    inherit stateDir;
    inherit (pkgs) lib;
    tomcat = pkgs.tomcat9;
    tomcatConstructorFun = constructors.simpleAppservingTomcat;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableTomcatWebApplication = true;
    });
  };

  disnixAppservingTomcat = import ./apache-tomcat/disnix-appserving-tomcat.nix {
    inherit stateDir processManager;
    inherit (pkgs) lib libmatthew_java dbus_java DisnixWebService;
    tomcat = pkgs.tomcat9;
    tomcatConstructorFun = constructors.simpleAppservingTomcat;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableTomcatWebApplication = true;
    });
  };

  docker = import ./docker {
    inherit (pkgs) lib;
    dockerConstructorFun = constructors.docker;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableDockerContainer = true;
    });
  };

  simpleInfluxdb = import ./influxdb/simpleinfluxdb.nix {
    influxdbConstructorFun = constructors.simpleInfluxdb;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableInfluxDatabase = true;
    });
    inherit (pkgs) lib;
  };

  simpleMongodb = import ./mongodb/simplemongodb.nix {
    inherit (pkgs) lib;
    mongodbConstructorFun = constructors.simpleMongodb;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableMongoDatabase = true;
    });
  };

  mysql = import ./mysql {
    inherit (pkgs) lib;
    inherit runtimeDir;
    mysqlConstructorFun = constructors.mysql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableMySQLDatabase = true;
    });
  };

  postgresql = import ./postgresql {
    inherit runtimeDir;
    inherit (pkgs) lib;
    postgresqlConstructorFun = constructors.postgresql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enablePostgreSQLDatabase = true;
    });
  };

  simplePostgresql = import ./postgresql/simplepostgresql.nix {
    inherit runtimeDir;
    inherit (pkgs) lib;
    postgresqlConstructorFun = constructors.simplePostgresql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enablePostgreSQLDatabase = true;
    });
  };

  extendableSupervisord = import ./supervisord/extendable.nix {
    inherit libDir;
    inherit (pkgs) lib;
    supervisordConstructorFun = constructors.extendableSupervisord;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSupervisordProgram = true;
    });
  };

  s6-svscan = import ./s6-svscan {
    inherit libDir runtimeDir;
    inherit (pkgs) lib;
    s6-svscanConstructorFun = constructors.s6-svscan;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableS6RCService = true;
    });
  };

  svnserve = import ./svnserve {
    inherit (pkgs) lib;
    svnserveConstructorFun = constructors.svnserve;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSubversionRepository = true;
    });
  };

  extendableXinetd = import ./xinetd/extendable.nix {
    inherit libDir;
    inherit (pkgs) lib;
    xinetdConstructorFun = constructors.extendableXinetd;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableXinetdService = true;
    });
  };
}
