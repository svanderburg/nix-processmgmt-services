{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "vsftpd";
  exprFile = ./processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };

  nixosConfig = {
    users.users.ftp = {
      description = "Anonymous FTP user";
      isNormalUser = true;
      createHome = true;
      password = "secret";
    };
  };

  systemPackages = [ pkgs.inetutils ];

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.listenPort})
    '';

  tests = {instanceName, instance, forceDisableUserChange, ...}:
    if forceDisableUserChange then ''
      machine.succeed("echo test > /home/unprivileged/test.txt")
      machine.succeed("chown unprivileged:users /home/unprivileged/test.txt")
      machine.succeed('(echo "user anonymous foobar"; echo "ls") | ftp -n 127.0.0.1 ${toString instance.listenPort} >&2')
      machine.succeed("curl --fail ftp://anonymous@localhost:${toString instance.listenPort}/test.txt -o test.txt")
      machine.succeed("grep test test.txt")
      machine.succeed("rm test.txt")
    '' else ''
      machine.succeed("echo test > /home/ftp/test.txt")
      machine.succeed("chown ftp:users /home/ftp/test.txt")
      machine.succeed("chmod a-w /home/ftp")
      machine.succeed('(echo "user anonymous foobar"; echo "ls") | ftp -n 127.0.0.1 ${pkgs.lib.optionalString (instance.listenPort != 21) (toString instance.listenPort)} >&2')
      machine.succeed("curl -v --fail ftp://anonymous@localhost${pkgs.lib.optionalString (instance.listenPort != 21) ":${toString instance.listenPort}"}/test.txt -o test.txt 2>&1")
      machine.succeed("grep test test.txt")
      machine.succeed("rm test.txt")
    '';

  inherit processManagers profiles;
}
