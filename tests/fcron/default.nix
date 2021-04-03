{ pkgs, testService, processManagers, profiles }:

testService {
  exprFile = ./processes.nix;

  readiness = {instanceName, instance, ...}:
    ''
    '';

  tests = {instanceName, instance, ...}:
    ''
      machine.succeed("sleep 70")
    ''
    +
    (if instanceName == "fcron" then ''
      machine.succeed("grep 'hello' /tmp/hello")
    ''
    else if instanceName == "fcron-secondary" then ''
      machine.succeed("grep 'bye' /tmp/bye")
    ''
    else "");

  inherit processManagers profiles;
}
