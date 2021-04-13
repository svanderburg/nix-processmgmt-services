{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "nginx" || instanceName == "nginx2")
      (pkgs.lib.concatMapStrings (webapp: ''
        machine.succeed(
            "curl --fail -H 'Host: ${webapp.dnsName}' http://localhost:${toString instance.port} | grep ': ${toString webapp.port}'"
        )
      '') instance.webapps);

  inherit processManagers profiles;
}
