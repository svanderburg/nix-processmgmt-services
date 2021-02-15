{ nix-processmgmt ? ../../nix-processmgmt
, pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
}:

let
  constructors = import ../services-agnostic/constructors.nix {
    inherit nix-processmgmt pkgs stateDir logDir runtimeDir cacheDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  simpleWebappApache = import ./apache/simple-webapp-apache.nix {
    apacheConstructorFun = constructors.simpleWebappApache;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableApacheWebApplication = true;
    });
    inherit forceDisableUserChange;
  };

  simpleAppservingTomcat = import ./apache-tomcat/simple-appserving-tomcat.nix {
    inherit stateDir;
    tomcatConstructorFun = constructors.simpleAppservingTomcat;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableTomcatWebApplication = true;
    });
  };

  simpleInfluxdb = import ./influxdb/simpleinfluxdb.nix {
    influxdbConstructorFun = constructors.simpleInfluxdb;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableInfluxDatabase = true;
    });
  };

  simpleMongodb = import ./mongodb/simplemongodb.nix {
    inherit (pkgs) stdenv;
    mongodbConstructorFun = constructors.simpleMongodb;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableMongoDatabase = true;
    });
  };

  mysql = import ./mysql {
    inherit runtimeDir;
    mysqlConstructorFun = constructors.mysql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableMySQLDatabase = true;
    });
  };

  postgresql = import ./postgresql {
    inherit runtimeDir;
    postgresqlConstructorFun = constructors.postgresql;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enablePostgreSQLDatabase = true;
    });
  };

  extendableSupervisord = import ./supervisord/extendable-supervisord.nix {
    inherit stateDir;
    inherit (pkgs) stdenv;
    supervisordConstructorFun = constructors.extendableSupervisord;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSupervisordProgram = true;
    });
  };

  svnserve = import ./svnserve {
    svnserveConstructorFun = constructors.svnserve;
    dysnomia = pkgs.dysnomia.override (origArgs: {
      enableSubversionRepository = true;
    });
  };
}
