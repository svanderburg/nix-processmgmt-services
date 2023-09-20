{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

let
  env = "NIX_PATH='nixpkgs=${<nixpkgs>}' SSH_OPTS='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' DISNIX_REMOTE_CLIENT=disnix-client";
in
testService {
  name = "disnix-with-apache-mysql";
  exprFile = ../../../example-deployments/disnix/processes-with-apache-mysql.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.disnix ];

  initialTests = {forceDisableUserChange, ...}:
    let
      homeDir = if forceDisableUserChange then "/home/unprivileged" else "/root";
    in
    ''
      machine.succeed("cd ${homeDir}")
      machine.succeed('ssh-keygen -t ecdsa -f key -N ""')
      machine.succeed("mkdir -m 700 ${homeDir}/.ssh")
      machine.succeed("cp key.pub ${homeDir}/.ssh/authorized_keys")
      machine.succeed("chmod 600 ${homeDir}/.ssh/authorized_keys")
      machine.succeed("cp key ${homeDir}/.ssh/id_dsa")
      machine.succeed("chmod 600 ${homeDir}/.ssh/id_dsa")
    '';

  readiness = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "sshd") ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, forceDisableUserChange, ...}:
    pkgs.lib.optionalString (instanceName == "disnix-service") ''
      machine.succeed(
          "${env} disnix-capture-infra ${../infra-bootstrap.nix} > infrastructure.nix"
      )

      # Check if the container services are present
      machine.succeed("grep 'process = {' infrastructure.nix")
      machine.succeed("grep 'apache-webapplication = {' infrastructure.nix")
      machine.succeed("grep 'mysql-database = {' infrastructure.nix")
    '';

  inherit processManagers;

  # We don't support unprivileged multi-user deployments
  profiles = builtins.filter (profile: profile == "privileged") profiles;
}
