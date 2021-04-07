{createManagedProcess, lib, hydra, nix, forceDisableUserChange}:
{nix-daemon ? null, hydra-server, user ? null, postgresqlDBMS ? null}:

# TODO: execStopPost: /bin/hydra-queue-runner --unlock

let
  instanceName = "hydra-queue-runner${hydra-server.instanceSuffix}";
  _user = if user == null then instanceName else user;
  queueRunnerBaseDir = "${hydra-server.baseDir}/queue-runner";
in
createManagedProcess {
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
    mkdir -m 0750 -p ${hydra-server.baseDir}/build-logs
  ''
  + lib.optionalString (!forceDisableUserChange) ''
    chown ${_user}:${hydra-server.hydraGroup} ${queueRunnerBaseDir} ${hydra-server.baseDir}/build-logs
  ''
  # Wait for the database to be created before starting
  + lib.optionalString (postgresqlDBMS != null) ''
    count=1

    while [ $count -lt 10 ]
    do
        if [ -e "${hydra-server.baseDir}/.db-created" ]
        then
            found=1
            break
        fi

        echo "Waiting for the Hydra database to get created..." >&2
        sleep 1
    done

    if [ "$found" != "1" ]
    then
        echo "ERRORDatabase was still not created!" >&2
        exit 1
    fi
  '';
  foregroundProcess = "${hydra}/bin/hydra-queue-runner";
  args = [ "-v" ];
  dependencies = [ hydra-server.pkg ]
    ++ lib.optional (nix-daemon != null) nix-daemon
    ++ lib.optional (postgresqlDBMS != null) postgresqlDBMS.pkg;

  credentials = {
    users = {
      "${_user}" = {
        group = hydra-server.hydraGroup;
        description = "Hydra queue runner";
        homeDir = queueRunnerBaseDir;
        createHomeDir = true;
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
        "Environment=IN_SYSTEMD" = "1";
      };
    };
  };
}
