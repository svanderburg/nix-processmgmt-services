{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  exprFile = ./processes.nix;
  systemPackages = [ pkgs.influxdb ];
  extraParams = {
    inherit nix-processmgmt;
  };

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.httpPort})
    '';

  tests = {instanceName, instance, runtimeDir, forceDisableUserChange, ...}:
    # Make a special exception for the first instance running in privileged mode. It should be connectible with the default settings
    if instanceName == "influxdb" && !forceDisableUserChange then ''
      machine.succeed("influx -execute 'show databases' >&2")
    '' else ''
      machine.succeed("influx -execute 'show databases' --port ${toString instance.httpPort} >&2")
    '';

  inherit processManagers profiles;
}
