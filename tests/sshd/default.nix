{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "sshd";
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.openssh ];

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
    ''
    + pkgs.lib.optionalString forceDisableUserChange ''
      machine.succeed("chown unprivileged:users key")
      machine.succeed("chown -R unprivileged:users ${homeDir}/.ssh")
    '';

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, forceDisableUserChange, ...}:
    # Make a special exception for the first instance running in privileged mode. It should be connectible with the default settings
    if instanceName == "sshd" && !forceDisableUserChange then ''
      machine.succeed(
          "ssh -i key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no localhost $(type -p ls) / >&2"
      )
    '' else ''
      machine.succeed(
          "${pkgs.lib.optionalString forceDisableUserChange "su unprivileged -c '"}ssh -p ${toString instance.port} -i key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no localhost $(type -p ls) /${pkgs.lib.optionalString forceDisableUserChange "'"} >&2"
      )
    '';

  inherit processManagers profiles;
}
