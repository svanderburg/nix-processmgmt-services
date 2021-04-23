{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.postgresql ];
  nixosConfig = {
    virtualisation.diskSize = 8192;
    virtualisation.memorySize = 1024;
  };

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, runtimeDir, forceDisableUserChange, ...}:
    # Make a special exception for the first instance running in privileged mode. It should be connectible with the default settings
    if instanceName == "postgresql" && !forceDisableUserChange then ''
      machine.succeed("su - postgresql -c 'psql -l'")
    '' else ''
      # fmt: off
      machine.succeed(
          "su - ${if forceDisableUserChange then "unprivileged" else instanceName} -c 'psql ${pkgs.lib.optionalString forceDisableUserChange "-U unprivileged"} -h ${runtimeDir}/${instanceName} --port ${toString instance.port} -l'"
      )
      # fmt: on
    '';

  inherit processManagers profiles;
}
