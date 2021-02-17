{createManagedProcess, hydra}:
{nix-daemon, hydra-server}:

let
  instanceName = "hydra-evaluator${hydra-server.instanceSuffix}";

  # TODO: ExecStopPost /bin/hydra-evaluator --unlock
in
createManagedProcess {
  name = instanceName;
  inherit instanceName;
  dependencies = [ nix-daemon.pkg hydra-server.pkg ];
  path = [ hydra ];
  environment = import ./generate-env-vars.nix {
    inherit (hydra-server) baseDir hydraDatabase hydraUser;
  };
  directory = hydra-server.baseDir;
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
