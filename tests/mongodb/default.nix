{ pkgs, testService, processManagers, profiles }:

testService {
  exprFile = ./processes.nix;
  systemPackages = [ pkgs.mongodb ];
  nixosConfig = {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 8192;
  };
  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, runtimeDir, forceDisableUserChange, ...}:
    # Make a special exception for the first instance running in privileged mode. It should be connectible with the default settings
    if instanceName == "mongodb" && !forceDisableUserChange then ''
      machine.succeed("echo 'show databases' | mongo >&2")
    '' else ''
      machine.succeed("echo 'show databases' | mongo --port ${toString instance.port} >&2")
    '';

  inherit processManagers profiles;
}
