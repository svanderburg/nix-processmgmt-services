{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "xinetd";
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.inetutils ];

  readiness = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "xinetd-secondary") ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, stateDir, ...}:
    if instanceName == "xinetd-primary" then ''
      machine.succeed("echo hello > ${stateDir}/hello.txt")
      # fmt: off
      machine.succeed(
          "(echo 'get ${stateDir}/hello.txt'; sleep 3; echo 'quit') | tftp 127.0.0.1 ${pkgs.lib.optionalString (instance.port != 69) (toString instance.port)}"
      )
      # fmt: on
      machine.succeed("grep 'hello' hello.txt")
    ''
    else if instanceName == "xinetd-secondary" then ''
      machine.succeed("(echo 'ls /'; sleep 3) | telnet localhost ${pkgs.lib.optionalString (instance.port != 23) (toString instance.port)} | grep bin")
    ''
    else "";

  inherit processManagers profiles;
}
