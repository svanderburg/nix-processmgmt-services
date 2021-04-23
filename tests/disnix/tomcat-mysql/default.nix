{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

let
  env = "NIX_PATH='nixpkgs=${<nixpkgs>}' DISNIX_CLIENT_INTERFACE=disnix-soap-client DISNIX_TARGET_PROPERTY=targetEPR DISNIX_SOAP_CLIENT_USERNAME=admin DISNIX_SOAP_CLIENT_PASSWORD=secret";
in
testService {
  exprFile = ../../../example-deployments/disnix/processes-with-tomcat-mysql.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.disnix pkgs.DisnixWebService ];

  readiness = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "sshd" || instanceName == "apache") ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, forceDisableUserChange, ...}:
    pkgs.lib.optionalString (instanceName == "disnix-service") ''
      machine.succeed(
          "${env} disnix-capture-infra ${./infra-bootstrap.nix} > infrastructure.nix"
      )

      # Check if the container services are present
      machine.succeed("grep 'process = {' infrastructure.nix")
      machine.succeed("grep 'tomcat-webapplication = {' infrastructure.nix")
      machine.succeed("grep 'mysql-database = {' infrastructure.nix")
    '';

  inherit processManagers;

  # We don't support unprivileged multi-user deployments
  profiles = builtins.filter (profile: profile == "privileged") profiles;
}
