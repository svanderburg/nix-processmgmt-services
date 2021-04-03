{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, processManagers ? [ "supervisord" "sysvinit" "systemd" "docker" "disnix" "s6-rc" ]
, profiles ? [ "privileged" "unprivileged" ]
, nix-processmgmt ? ../../nix-processmgmt
}:

let
  testService = import "${nix-processmgmt}/nixproc/test-driver/universal.nix" {
    inherit system;
  };
in
{
  apache = import ./apache {
    inherit pkgs processManagers profiles testService;
  };

  apache-tomcat = import ./apache-tomcat {
    inherit pkgs processManagers profiles testService;
  };

  apache-tomcat-ajp-reverse-proxy = import ./apache-tomcat-ajp-reverse-proxy {
    inherit pkgs processManagers profiles testService;
  };

  docker = import ./docker {
    inherit pkgs processManagers profiles testService;
  };

  fcron = import ./fcron {
    inherit pkgs processManagers profiles testService;
  };

  influxdb = import ./influxdb {
    inherit pkgs processManagers profiles testService;
  };

  mongodb = import ./mongodb {
    inherit pkgs processManagers profiles testService;
  };

  mysql = import ./mysql {
    inherit pkgs processManagers profiles testService;
  };

  nginx = import ./nginx {
    inherit pkgs processManagers profiles testService;
  };

  nginx-reverse-proxy-hostbased = import ./nginx-reverse-proxy-hostbased {
    inherit pkgs processManagers profiles testService nix-processmgmt;
  };

  nginx-reverse-proxy-pathbased = import ./nginx-reverse-proxy-pathbased {
    inherit pkgs processManagers profiles testService;
  };

  postgresql = import ./postgresql {
    inherit pkgs processManagers profiles testService;
  };

  s6-svscan = import ./s6-svscan {
    inherit pkgs processManagers profiles testService;
  };

  sshd = import ./sshd {
    inherit pkgs processManagers profiles testService;
  };

  supervisord = import ./supervisord {
    inherit pkgs processManagers profiles testService;
  };

  svnserve = import ./svnserve {
    inherit pkgs processManagers profiles testService;
  };
}
