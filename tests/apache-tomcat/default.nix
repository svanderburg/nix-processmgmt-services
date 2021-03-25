{ pkgs, testService, processManagers, profiles }:

testService {
  exprFile = ./processes.nix;

  nixosConfig = {
    virtualisation.diskSize = 8192;
    virtualisation.memorySize = 1024;
  };

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.httpPort})
    '';

  tests = {instanceName, instance, ...}:
    ''
      machine.succeed(
          "curl --fail http://localhost:${toString instance.httpPort}/examples/servlets/servlet/HelloWorldExample | grep 'Hello World!'"
      )
    '';

  inherit processManagers profiles;
}
