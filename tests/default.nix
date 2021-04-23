{ nixpkgs ? <nixpkgs>
, system ? builtins.currentSystem
, processManagers ? [ "supervisord" "sysvinit" "systemd" "docker" "disnix" "s6-rc" ]
, profiles ? [ "privileged" "unprivileged" ]
, nix-processmgmt ? ../../nix-processmgmt
}:

let
  pkgs = import nixpkgs { inherit system; };

  testService = import "${nix-processmgmt}/nixproc/test-driver/universal.nix" {
    inherit nixpkgs system;
  };
in
{
  apache = import ./apache {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  apache-tomcat = import ./apache-tomcat {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  apache-tomcat-ajp-reverse-proxy = import ./apache-tomcat-ajp-reverse-proxy {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  disnix = import ./disnix/bare {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  disnix-with-apache-mysql = import ./disnix/apache-mysql {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  disnix-with-tomcat-mysql = import ./disnix/tomcat-mysql {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  disnix-with-tomcat-mysql-multi-instance = import ./disnix/tomcat-mysql-multi-instance {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  docker = import ./docker {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  fcron = import ./fcron {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  hydra = import ./hydra {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  influxdb = import ./influxdb {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  mongodb = import ./mongodb {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  mysql = import ./mysql {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  nginx = import ./nginx/simple-webapp {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  nginx-reverse-proxy-hostbased = import ./nginx/reverse-proxy-hostbased {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  nginx-reverse-proxy-pathbased = import ./nginx/reverse-proxy-pathbased {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  postgresql = import ./postgresql {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  s6-svscan = import ./s6-svscan {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  sshd = import ./sshd {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  supervisord = import ./supervisord {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  svnserve = import ./svnserve {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  xinetd = import ./xinetd/declarative {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  xinetd-extendable = import ./xinetd/extendable {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };
}
