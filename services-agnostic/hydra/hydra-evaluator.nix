{createManagedProcess, lib, hydra}:
{nix-daemon ? null, hydra-server, postgresqlDBMS ? null}:

let
  instanceName = "hydra-evaluator${hydra-server.instanceSuffix}";

  # TODO: ExecStopPost /bin/hydra-evaluator --unlock
in
createManagedProcess {
  inherit instanceName;

  dependencies = [ hydra-server.pkg ]
    ++ lib.optional (nix-daemon != null) nix-daemon.pkg
    ++ lib.optional (postgresqlDBMS != null) postgresqlDBMS.pkg;
  path = [ hydra ];
  environment = import ./generate-env-vars.nix {
    inherit (hydra-server) baseDir hydraDatabase hydraUser;
  };
  directory = hydra-server.baseDir;
  initialize = lib.optionalString (postgresqlDBMS != null) ''
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
        echo "ERROR: Database was still not created!" >&2
        exit 1
    fi
  '';
  foregroundProcess = "${hydra}/bin/hydra-evaluator";
  user = hydra-server.hydraUser;

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
    systemd = {
      Service.Restart = "always";
    };
  };
}
