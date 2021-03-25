{ pkgs, testService, processManagers, profiles }:

testService {
  exprFile = ./processes.nix;

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, ...}:
    ''
      machine.succeed("curl --fail http://localhost:${toString instance.port} | grep 'Hello world!'")
    '';

  inherit processManagers profiles;
}
