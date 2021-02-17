{createManagedProcess, stdenv, hydra, nix, forceDisableUserChange}:
{nix-daemon, hydra-server, user ? null}:

# TODO: execStopPost: /bin/hydra-queue-runner --unlock

let
  instanceName = "hydra-queue-runner${hydra-server.instanceSuffix}";
  _user = if user == null then instanceName else user;
  queueRunnerBaseDir = "${hydra-server.baseDir}/queue-runner";
in
createManagedProcess {
  name = instanceName;
  inherit instanceName;
  environment = import ./generate-env-vars.nix {
    inherit (hydra-server) baseDir hydraDatabase hydraUser;
  } // {
    LOGNAME = "hydra-queue-runner";
  };
  user = _user;
  path = [ nix ];
  directory = queueRunnerBaseDir;
  initialize = ''
    mkdir -m 0700 -p ${queueRunnerBaseDir}
    mkdir -m 0750 -p ${hydra-server.baseDir}/build-logs
    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${hydra-server.hydraGroup} ${queueRunnerBaseDir} ${hydra-server.baseDir}/build-logs
    ''}
  '';
  foregroundProcess = "${hydra}/bin/hydra-queue-runner";
  args = [ "-v" ];
  dependencies = [ nix-daemon.pkg hydra-server.pkg ];

  credentials = {
    users = {
      "${user}" = {
        group = hydra-server.hydraGroup;
        description = "Hydra queue runner";
        homeDir = queueRunnerBaseDir;
        shell = "/bin/sh";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
    systemd = {
      Service = {
        Restart = "always";
        LimitCORE = "infinity";
        Environment = {
          IN_SYSTEMD = "1";
        };
      };
    };
  };
}
