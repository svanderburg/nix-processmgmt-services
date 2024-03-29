{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "mysql";
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.mysql ];

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, runtimeDir, forceDisableUserChange, ...}:
    # Make a special exception for the first instance running in privileged mode. It should be connectible with the default settings
    if instanceName == "mysql" && !forceDisableUserChange && runtimeDir == "/var/run" then ''
      machine.succeed("echo 'show databases;' | mysql >&2")
    '' else ''
      machine.succeed(
          "echo 'show databases;' | mysql -S ${runtimeDir}/mysqld${instance.instanceSuffix}/mysqld.sock >&2"
      )
    '';

  inherit processManagers profiles;
}
