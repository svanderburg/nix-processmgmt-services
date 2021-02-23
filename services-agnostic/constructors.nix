{ nix-processmgmt ? ../../nix-processmgmt
, pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, spoolDir
, tmpDir
, forceDisableUserChange
, processManager
, ids ? {}
}:

let
  createManagedProcess = import "${nix-processmgmt}/nixproc/create-managed-process/universal/create-managed-process-universal.nix" {
    inherit pkgs runtimeDir stateDir logDir tmpDir forceDisableUserChange processManager ids;
  };
in
{
  apache = import ./apache {
    inherit createManagedProcess cacheDir;
    inherit (pkgs) apacheHttpd;
  };

  simpleWebappApache = import ./apache/simple-webapp-apache.nix {
    inherit createManagedProcess logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv runCommand apacheHttpd php writeTextFile;
  };

  reverseProxyApache = import ./apache/reverse-proxy-apache.nix {
    inherit createManagedProcess logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv runCommand apacheHttpd php writeTextFile;
  };

  tomcat = import ./apache-tomcat {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) stdenv;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };

  simpleAppservingTomcat = import ./apache-tomcat/simple-appserving-tomcat.nix {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) stdenv;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };

  docker = import ./docker {
    inherit createManagedProcess;
    inherit (pkgs) docker kmod;
  };

  fcron = import ./fcron {
    inherit createManagedProcess stateDir spoolDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) writeTextFile fcron;
  };

  hydra-evaluator = import ./hydra/hydra-evaluator.nix {
    inherit createManagedProcess;
    hydra = pkgs.hydra-unstable;
  };

  hydra-queue-runner = import ./hydra/hydra-queue-runner.nix {
    inherit (pkgs) stdenv nix;
    inherit createManagedProcess forceDisableUserChange;
    hydra = pkgs.hydra-unstable;
  };

  hydra-server = import ./hydra/hydra-server.nix {
    inherit createManagedProcess stateDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile postgresql su;
    hydra = pkgs.hydra-unstable;
  };

  influxdb = import ./influxdb {
    inherit createManagedProcess stateDir;
    inherit (pkgs) influxdb;
  };

  simpleInfluxdb = import ./influxdb/simpleinfluxdb.nix {
    inherit createManagedProcess stateDir;
    inherit (pkgs) influxdb writeTextFile;
  };

  mongodb = import ./mongodb {
    inherit createManagedProcess runtimeDir;
    inherit (pkgs) mongodb;
  };

  simpleMongodb = import ./mongodb/simplemongodb.nix {
    inherit createManagedProcess runtimeDir stateDir forceDisableUserChange;
    inherit (pkgs) stdenv mongodb writeTextFile;
  };

  mysql = import ./mysql {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv mysql;
  };

  nginx = import ./nginx {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv nginx;
  };

  nginxReverseProxyHostBased = import ./nginx/nginx-reverse-proxy-hostbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile nginx;
  };

  nginxReverseProxyPathBased = import ./nginx/nginx-reverse-proxy-pathbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile nginx;
  };

  nix-daemon = import ./nix-daemon {
    inherit createManagedProcess;
    inherit (pkgs) nix;
  };

  openssh = import ./openssh {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) writeTextFile openssh;
  };

  postgresql = import ./postgresql {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv postgresql su;
  };

  simplePostgresql = import ./postgresql/simplepostgresql.nix {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv writeTextFile postgresql su;
  };

  s6-svscan = import ./s6-svscan {
    inherit createManagedProcess runtimeDir;
    inherit (pkgs) s6;
  };

  supervisord = import ./supervisord {
    inherit createManagedProcess runtimeDir logDir;
    inherit (pkgs.pythonPackages) supervisor;
  };

  extendableSupervisord = import ./supervisord/extendable-supervisord.nix {
    inherit createManagedProcess stateDir runtimeDir logDir;
    inherit (pkgs) writeTextFile;
    inherit (pkgs.pythonPackages) supervisor;
  };

  svnserve = import ./svnserve {
    inherit createManagedProcess runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv subversion;
  };
}
