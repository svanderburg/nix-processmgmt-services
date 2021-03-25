{ pkgs, testService, processManagers, profiles }:

testService {
  exprFile = ./processes.nix;
  systemPackages = [ pkgs.subversion ];

  readiness = {instanceName, instance, ...}:
    ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  tests = {instanceName, instance, stateDir, forceDisableUserChange, ...}:
    ''
      # fmt: off
      machine.succeed(
          "mkdir -p ${instance.svnBaseDir}"
      )
      machine.succeed(
          "svnadmin create ${instance.svnBaseDir}/testrepo-${instanceName}"
      )
      # fmt: on
    ''
    # Make a special exception for the first instance running in privileged mode. It should be connectible with the default settings
    + (if instanceName == "svnserve" && !forceDisableUserChange then ''
      # fmt: off
      machine.succeed(
          "svn co svn://localhost/testrepo-${instanceName}"
      )
      # fmt: on
    '' else ''
      # fmt: off
      machine.succeed(
          "svn co svn://localhost:${toString instance.port}/testrepo-${instanceName}"
      )
      # fmt: on
    '');

  inherit processManagers profiles;
}
