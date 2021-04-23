{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  systemPackages = [ pkgs.inetutils ];

  tests = {instanceName, instance, stateDir, runtimeDir, forceDisableUserChange, ...}:
    if instanceName == "xinetd-primary" then
      let
        tftpService = pkgs.writeTextFile {
          name = "tftp";
          text = ''
            service tftp
            {
                socket_type = dgram
                protocol = udp
                bind = 127.0.0.1
                wait = yes
                user = ${if forceDisableUserChange then "unprivileged" else "root"}
                server = ${pkgs.inetutils}/libexec/tftpd
                server_args = -u ${if forceDisableUserChange then "unprivileged" else "nobody"}
                disable = no
                type = UNLISTED
                port = ${toString instance.port}
            }
          '';
        };
      in
      ''
        machine.succeed("mkdir -p ${stateDir}/lib/${instanceName}/xinetd.d")
        machine.succeed(
            "cp ${tftpService} ${stateDir}/lib/${instanceName}/xinetd.d"
        )
        machine.succeed("kill -HUP $(cat ${runtimeDir}/${instanceName}.pid)")

        machine.succeed("echo hello > ${stateDir}/hello.txt")
        # fmt: off
        machine.succeed(
            "(echo 'get ${stateDir}/hello.txt'; sleep 3; echo 'quit') | tftp 127.0.0.1 ${pkgs.lib.optionalString (instance.port != 69) (toString instance.port)}"
        )
        # fmt: on
        machine.succeed("grep 'hello' hello.txt")
      ''
    else if instanceName == "xinetd-secondary" then
      let
        telnetService = pkgs.writeTextFile {
          name = "telnet";
          text = ''
            service telnet
            {
                flags = REUSE
                socket_type = stream
                wait = no
                user = ${if forceDisableUserChange then "unprivileged" else "root"}
                server = ${pkgs.inetutils}/libexec/telnetd
                server_args = -E ${pkgs.bashInteractive}/bin/bash
                disable = no
                instances = 10
                type = UNLISTED
                port = ${toString instance.port}
            }
          '';
        };
      in
      ''
        machine.succeed("mkdir -p ${stateDir}/lib/${instanceName}/xinetd.d")
        machine.succeed(
            "cp ${telnetService} ${stateDir}/lib/${instanceName}/xinetd.d"
        )
        machine.succeed("kill -HUP $(cat ${runtimeDir}/${instanceName}.pid)")

        machine.succeed("(echo 'ls /'; sleep 3) | telnet localhost ${pkgs.lib.optionalString (instance.port != 23) (toString instance.port)} | grep bin")
      ''
    else "";

  inherit processManagers profiles;
}
