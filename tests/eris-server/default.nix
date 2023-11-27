{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

testService {
  name = "eris-server";
  exprFile = ./processes.nix;
  extraParams = { inherit pkgs nix-processmgmt; };
  inherit processManagers profiles;

  systemPackages = [ pkgs.eris-go ];
  readiness = { instanceName, instance, ... }: ''
    machine.wait_for_open_port(5680)
    machine.wait_for_open_port(5683)
  '';
  tests = { instanceName, instance, stateDir, forceDisableUserChange, ... }: ''
    machine.succeed(
        "eris-go get http://[::1]:5680 $(echo 'Hail ERIS!' | eris-go put coap+tcp://[::1]:5683)"
    )
  '';
}
