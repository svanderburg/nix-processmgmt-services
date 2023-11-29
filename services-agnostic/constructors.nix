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
, callingUser ? null
, callingGroup ? null
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
    inherit (pkgs) lib runCommand apacheHttpd php writeTextFile;
  };

  reverseProxyApache = import ./apache/reverse-proxy-apache.nix {
    inherit createManagedProcess logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv lib runCommand apacheHttpd php writeTextFile;
  };

  basicAuthReverseProxyApache = import ./apache/basic-auth-reverse-proxy-apache.nix {
    inherit createManagedProcess logDir cacheDir runtimeDir forceDisableUserChange;
    inherit (pkgs) stdenv lib runCommand apacheHttpd php writeTextFile;
  };

  tomcat = import ./apache-tomcat {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) lib;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };

  simpleAppservingTomcat = import ./apache-tomcat/simple-appserving-tomcat.nix {
    inherit createManagedProcess stateDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) stdenv lib;
    jre = pkgs.jre8;
    tomcat = pkgs.tomcat9;
  };

  dbus-daemon = import ./dbus-daemon {
    inherit createManagedProcess libDir runtimeDir ids;
    inherit (pkgs) lib dbus writeTextFile;
  };

  disnix-service = import ./disnix-service {
    inherit createManagedProcess nix-processmgmt ids processManager;
    inherit (pkgs) stdenv lib writeTextFile nix disnix dysnomia inetutils findutils;
  };

  docker = import ./docker {
    inherit createManagedProcess runtimeDir libDir;
    inherit (pkgs) docker kmod;
  };

  fcron = import ./fcron {
    inherit createManagedProcess stateDir spoolDir runtimeDir tmpDir forceDisableUserChange callingUser callingGroup;
    inherit (pkgs) lib writeTextFile fcron;
  };

  declarativeFcron = import ./fcron/declarative.nix {
    inherit createManagedProcess stateDir spoolDir runtimeDir tmpDir forceDisableUserChange callingUser callingGroup;
    inherit (pkgs) lib writeTextFile fcron utillinux;
  };

  hydra-evaluator = import ./hydra/hydra-evaluator.nix {
    inherit createManagedProcess;
    inherit (pkgs) lib;
    hydra = pkgs.hydra-unstable;
  };

  hydra-queue-runner = import ./hydra/hydra-queue-runner.nix {
    inherit (pkgs) lib nix;
    inherit createManagedProcess forceDisableUserChange;
    hydra = pkgs.hydra-unstable;
  };

  hydra-server = import ./hydra/hydra-server.nix {
    inherit createManagedProcess libDir forceDisableUserChange;
    inherit (pkgs) lib writeTextFile postgresql su;
    hydra = pkgs.hydra-unstable;
  };

  influxdb = import ./influxdb {
    inherit createManagedProcess libDir;
    inherit (pkgs) influxdb;
  };

  simpleInfluxdb = import ./influxdb/simpleinfluxdb.nix {
    inherit createManagedProcess libDir;
    inherit (pkgs) influxdb writeTextFile;
  };

  mongodb = import ./mongodb {
    inherit createManagedProcess tmpDir;
    inherit (pkgs) mongodb;
  };

  simpleMongodb = import ./mongodb/simplemongodb.nix {
    inherit createManagedProcess tmpDir stateDir forceDisableUserChange;
    inherit (pkgs) lib mongodb writeTextFile;
  };

  mysql = import ./mysql {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) lib mysql;
  };

  nginx = import ./nginx {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) lib nginx;
  };

  simpleWebappNginx = import ./nginx/simple-webapp-nginx.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) lib nginx writeTextFile;
  };

  nginxReverseProxyHostBased = import ./nginx/reverse-proxy-hostbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv lib writeTextFile nginx;
  };

  nginxReverseProxyPathBased = import ./nginx/reverse-proxy-pathbased.nix {
    inherit createManagedProcess stateDir runtimeDir cacheDir forceDisableUserChange;
    inherit (pkgs) stdenv lib writeTextFile nginx;
  };

  nix-daemon = import ./nix-daemon {
    inherit createManagedProcess;
    inherit (pkgs) nix;
  };

  sshd = import ./sshd {
    inherit createManagedProcess libDir runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) writeTextFile openssh;
  };

  postgresql = import ./postgresql {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) lib postgresql su;
  };

  simplePostgresql = import ./postgresql/simplepostgresql.nix {
    inherit createManagedProcess stateDir runtimeDir forceDisableUserChange;
    inherit (pkgs) lib writeTextFile postgresql su;
  };

  s6-svscan = import ./s6-svscan {
    inherit createManagedProcess runtimeDir;
    inherit (pkgs) s6 execline;
  };

  supervisord = import ./supervisord {
    inherit createManagedProcess runtimeDir logDir;
    inherit (pkgs.python3Packages) supervisor;
  };

  extendableSupervisord = import ./supervisord/extendable.nix {
    inherit createManagedProcess libDir runtimeDir logDir;
    inherit (pkgs) writeTextFile;
    inherit (pkgs.python3Packages) supervisor;
  };

  svnserve = import ./svnserve {
    inherit createManagedProcess runtimeDir forceDisableUserChange;
    inherit (pkgs) lib subversion;
  };

  xinetd = import ./xinetd {
    inherit createManagedProcess runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) xinetd;
  };

  declarativeXinetd = import ./xinetd/declarative.nix {
    inherit createManagedProcess runtimeDir tmpDir forceDisableUserChange;
    inherit (pkgs) xinetd lib writeTextFile;
  };

  extendableXinetd = import ./xinetd/extendable.nix {
    inherit createManagedProcess runtimeDir tmpDir libDir forceDisableUserChange callingUser;
    inherit (pkgs) lib xinetd writeTextFile;
  };

  vsftpd = import ./vsftpd {
    inherit createManagedProcess;
    inherit (pkgs) vsftpd;
  };

  simpleVsftpd = import ./vsftpd/simple.nix {
    inherit createManagedProcess forceDisableUserChange logDir libDir callingUser callingGroup;
    inherit (pkgs) stdenv vsftpd writeTextFile lib;
  };

  agetty = import ./agetty {
    inherit createManagedProcess;
    inherit (pkgs) util-linux;
  };

  zerotierone = import ./zerotierone {
    inherit createManagedProcess libDir;
    inherit (pkgs) lib zerotierone;
  };
}
