{createManagedProcess, stdenv, lib, writeTextFile, nix, disnix, dysnomia, inetutils, processManager, nix-processmgmt}:

{ dbus-daemon ? null
, dysnomiaProperties ? {}
, dysnomiaContainers ? {}
, processManagerContainerSettings ? {}
}:

let
  group = "disnix";

  dysnomiaFlags =
    if processManager == "supervisord" then {
      enableSupervisordProgram = true;
    } else {};

  dysnomiaPkg = dysnomia.override dysnomiaFlags;
in
createManagedProcess {
  name = "disnix-service";
  process = "${disnix}/bin/disnix-service";
  path = [ nix dysnomiaPkg disnix inetutils ];
  environment = import ./dysnomia-env.nix {
    inherit stdenv lib writeTextFile nix-processmgmt processManager dysnomiaProperties dysnomiaContainers processManagerContainerSettings;
  };
  daemonExtraArgs = [ "--daemon" ];
  dependencies = lib.optional (dbus-daemon != null) dbus-daemon.pkg;

  credentials = {
    groups = {
      "${group}" = {};
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };
}
