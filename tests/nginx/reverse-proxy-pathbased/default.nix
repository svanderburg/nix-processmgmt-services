{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "nginx-reverse-proxy-pathbased";
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };

  nixosConfig = {
    virtualisation.memorySize = 1024;
  };

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "nginx-revproxy1" || instanceName == "nginx-revproxy2") ''
      machine.succeed("curl --fail http://localhost:${toString instance.port} | grep 'Hello world!'")
    '';

  inherit processManagers profiles;
}
