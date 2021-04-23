{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };

  readiness = {instanceName, instance, stateDir, ...}:
    if instanceName == "tomcat" then ''
      machine.wait_for_open_port(${toString instance.httpPort})
      machine.wait_for_file("${stateDir}/tomcat/webapps/examples")
    ''
    else if instanceName == "apache" then ''
      machine.wait_for_open_port(${toString instance.port})
    ''
    else "";

  tests = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "apache") ''
      machine.succeed("sleep 20")
      machine.succeed(
          "curl --fail http://localhost:${toString instance.port}/examples/servlets/servlet/HelloWorldExample | grep 'Hello World!'"
      )
    '';

  inherit processManagers profiles;
}
