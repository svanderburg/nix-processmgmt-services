{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "apache";
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, ...}:
    ''
      machine.succeed("curl --fail http://localhost:${toString instance.port} | grep 'Hello world'")
    '';

  inherit processManagers profiles;
}
